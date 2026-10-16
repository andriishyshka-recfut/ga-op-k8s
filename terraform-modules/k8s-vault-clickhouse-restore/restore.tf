locals {
  restore_target = var.RestoreDatabase == "" ? "ALL EXCEPT DATABASES system, information_schema, INFORMATION_SCHEMA" : "DATABASE `${replace(replace(var.RestoreDatabase, "\\", "\\\\"), "`", "\\`")}`"
  restore_query  = "RESTORE ${local.restore_target} ON CLUSTER '${local.clickhouse_cluster}' FROM Disk('${local.backup_disk_name}', '${var.RestoreBackupName}')"

  restore_script = <<-EOT
    set -euo pipefail
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
    clickhouse-client \
      --config-file /tmp/clickhouse-client.xml \
      --host "$CLICKHOUSE_HOST" \
      --secure --port 9440 \
      --query "$RESTORE_QUERY"
  EOT
}

resource "kubernetes_job_v1" "restore" {
  metadata {
    name      = local.restore_job_name
    namespace = local.namespace
  }

  spec {
    # A failed restore may leave partial data; retry only with a new run ID.
    backoff_limit = 0

    template {
      metadata {}

      spec {
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

        container {
          name    = "restore"
          image   = local.clickhouse_image
          command = ["/bin/bash", "-ec", local.restore_script]

          env {
            name  = "CLICKHOUSE_HOST"
            value = local.clickhouse_host
          }

          env {
            name  = "RESTORE_QUERY"
            value = local.restore_query
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
        }

        restart_policy = "Never"
      }
    }
  }

  wait_for_completion = true

  timeouts {
    create = "725m"
    update = "725m"
  }

  lifecycle {
    precondition {
      condition     = local.clickhouse.enabled && local.clickhouse.backup.enabled
      error_message = "ClickHouse and its backup disk must be enabled before restoring."
    }
  }
}
