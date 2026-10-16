locals {
  backup_script = <<-EOT
    set -euo pipefail
    trap 'touch /status/failed' ERR
    cat > /tmp/clickhouse-client.xml <<'XML'
    <config>
      <openSSL>
        <client>
          <caConfig>/etc/clickhouse-client/tls/ca.crt</caConfig>
          <verificationMode>strict</verificationMode>
          <invalidCertificateHandler>
            <name>RejectCertificateHandler</name>
          </invalidCertificateHandler>
        </client>
      </openSSL>
    </config>
    XML
    backup_name="full-$(date -u '+%Y%m%dT%H%M%SZ')"
    clickhouse-client \
      --config-file /tmp/clickhouse-client.xml \
      --host "$CLICKHOUSE_HOST" \
      --secure --port 9440 \
      --query "BACKUP ALL EXCEPT DATABASES system, information_schema, INFORMATION_SCHEMA ON CLUSTER '${local.clickhouse_cluster}' TO Disk('${local.backup_disk_name}', '$${backup_name}')"
    printf '%s\n' "$backup_name" > /status/backup-name
    touch /status/succeeded
  EOT

  retention_script = <<-EOT
    set -euo pipefail
    while true; do
      if [[ -f /status/succeeded || -f /status/failed ]]; then
        break
      fi
      sleep 5
    done
    if [[ ! -f /status/succeeded ]]; then
      exit 1
    fi

    backup_name="$(cat /status/backup-name)"
    if [[ ! "$backup_name" =~ ^full-[0-9]{8}T[0-9]{6}Z$ ]]; then
      echo "Invalid backup name: $backup_name" >&2
      exit 1
    fi
    aws --endpoint-url "$MINIO_ENDPOINT" s3api put-object \
      --bucket "${local.bucket}" \
      --key "${local.path}/${local.cluster_name}/$backup_name/.complete" \
      --body /status/succeeded > /dev/null

    cutoff="$(date -u -d '-${local.retention_days} days' '+%Y%m%dT%H%M%SZ')"
    directories="$(aws --endpoint-url "$MINIO_ENDPOINT" s3 ls "${local.minio_backup_target}/" | awk '$1 == "PRE" {print $2}' | LC_ALL=C sort -r)"
    completed=0
    while read -r directory; do
      if [[ ! "$directory" =~ ^full-[0-9]{8}T[0-9]{6}Z/$ ]]; then
        continue
      fi

      if ! marker_error="$(aws --endpoint-url "$MINIO_ENDPOINT" s3api head-object \
        --bucket "${local.bucket}" \
        --key "${local.path}/${local.cluster_name}/$directory.complete" 2>&1)"; then
        if [[ "$marker_error" == *"(404)"* || "$marker_error" == *"(NotFound)"* ]]; then
          continue
        fi
        echo "$marker_error" >&2
        exit 1
      fi

      completed=$((completed + 1))
      timestamp="$${directory#full-}"
      timestamp="$${timestamp%/}"
      if [[ "$completed" -gt "${local.minimum_backups}" && "$timestamp" < "$cutoff" ]]; then
        echo "Deleting expired backup: $directory"
        aws --endpoint-url "$MINIO_ENDPOINT" s3 rm "${local.minio_backup_target}/$directory" --recursive
      fi
    done <<< "$directories"
    echo "Retention cleanup finished successfully"
  EOT
}

resource "kubernetes_cron_job_v1" "backup" {
  lifecycle {
    precondition {
      condition     = local.minimum_backups >= 1 && floor(local.minimum_backups) == local.minimum_backups && local.retention_days >= 1 && floor(local.retention_days) == local.retention_days
      error_message = "Backup minimum_backups and retention_days must be positive integers."
    }
  }

  metadata {
    name      = "${local.cluster_name}-backup"
    namespace = local.namespace
  }

  spec {
    schedule                      = local.schedule
    concurrency_policy            = "Forbid"
    failed_jobs_history_limit     = 3
    successful_jobs_history_limit = 10

    job_template {
      metadata {}

      spec {
        template {
          metadata {
            annotations = {
              "sidecar.istio.io/inject" = "false"
            }
          }

          spec {
            image_pull_secrets {
              name = "harbor"
            }

            volume {
              name = "clickhouse-tls"
              secret {
                secret_name = local.clickhouse_tls_secret
                items {
                  key  = "ca.crt"
                  path = "ca.crt"
                }
              }
            }

            volume {
              name = "status"
              empty_dir {}
            }

            container {
              name    = "backup"
              image   = local.clickhouse_image
              command = ["/bin/bash", "-ec", local.backup_script]

              env {
                name  = "CLICKHOUSE_HOST"
                value = local.clickhouse_host
              }

              env {
                name = "CLICKHOUSE_USER"
                value_from {
                  secret_key_ref {
                    name = local.clickhouse_secret
                    key  = "username"
                  }
                }
              }

              env {
                name = "CLICKHOUSE_PASSWORD"
                value_from {
                  secret_key_ref {
                    name = local.clickhouse_secret
                    key  = "password"
                  }
                }
              }

              volume_mount {
                name       = "clickhouse-tls"
                mount_path = "/etc/clickhouse-client/tls"
                read_only  = true
              }

              volume_mount {
                name       = "status"
                mount_path = "/status"
              }
            }

            container {
              name    = "retention"
              image   = local.minio_client_image
              command = ["/bin/bash", "-ec", local.retention_script]

              env {
                name = "AWS_ACCESS_KEY_ID"
                value_from {
                  secret_key_ref {
                    name = local.minio_secret
                    key  = "access_key"
                  }
                }
              }

              env {
                name = "AWS_SECRET_ACCESS_KEY"
                value_from {
                  secret_key_ref {
                    name = local.minio_secret
                    key  = "secret_key"
                  }
                }
              }

              env {
                name  = "MINIO_ENDPOINT"
                value = local.endpoint
              }

              volume_mount {
                name       = "status"
                mount_path = "/status"
              }
            }

            restart_policy = "Never"
          }
        }
      }
    }
  }
}
