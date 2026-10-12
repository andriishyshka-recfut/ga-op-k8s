/*
data "vault_generic_secret" "backup_minio_auth" {
  count = local.backup_enabled ? 1 : 0
  path  = local.backup_minio_vault_path
}

resource "kubernetes_secret" "backup_minio" {
  count = local.backup_enabled ? 1 : 0

  metadata {
    name      = local.backup_secret_name
    namespace = local.namespace
  }

  data = {
    access_key = jsondecode(data.vault_generic_secret.backup_minio_auth[0].data[local.backup_minio_user]).accessKey
    secret_key = jsondecode(data.vault_generic_secret.backup_minio_auth[0].data[local.backup_minio_user]).secretKey
  }
}

locals {
  backup_common_packages = "apt-get update -qq && apt-get install -yqq ca-certificates gzip rdiff wget"
  backup_mc_install      = <<-EOT
    wget --quiet https://dl.min.io/client/mc/release/linux-amd64/mc -O /usr/local/bin/mc
    chmod +x /usr/local/bin/mc
  EOT
  backup_mc_env          = "MC_HOST_${local.backup_minio_alias}"
  backup_mc_host         = startswith(local.backup_minio_endpoint, "https://") ? replace(local.backup_minio_endpoint, "https://", "https://$(MINIO_ACCESS_KEY):$(MINIO_SECRET_KEY)@") : replace(local.backup_minio_endpoint, "http://", "http://$(MINIO_ACCESS_KEY):$(MINIO_SECRET_KEY)@")

  weekly_backup_script = <<-EOT
    set -euo pipefail
    ${local.backup_common_packages}
    ${local.backup_mc_install}
    timestamp="$(date -u '+%Y%m%dT%H%M%SZ')"
    backup_file="/tmp/${local.cluster_name}-weekly-${timestamp}.sql.gz"
    pg_dumpall --host="$POSTGRES_HOST" --port="$POSTGRES_PORT" --username="$POSTGRES_USERNAME" | gzip -9 > "$backup_file"
    mc cp "$backup_file" "${local.backup_minio_alias}/${local.backup_bucket}/${local.backup_path}/weekly/"
    mc rm --force --recursive --older-than "${local.backup_weekly_retention}" "${local.backup_minio_alias}/${local.backup_bucket}/${local.backup_path}/weekly/"
  EOT

  daily_incremental_script = <<-EOT
    set -euo pipefail
    ${local.backup_common_packages}
    ${local.backup_mc_install}
    timestamp="$(date -u '+%Y%m%dT%H%M%SZ')"
    current_dump="/tmp/${local.cluster_name}-daily-${timestamp}.sql.gz"
    base_dump="/tmp/${local.cluster_name}-weekly-base.sql.gz"
    delta_file="/tmp/${local.cluster_name}-daily-${timestamp}.delta"
    metadata_file="/tmp/${local.cluster_name}-daily-${timestamp}.meta"
    latest_weekly="$(mc find "${local.backup_minio_alias}/${local.backup_bucket}/${local.backup_path}/weekly/" --name "*.sql.gz" | sort | tail -1)"
    if [ -z "$latest_weekly" ]; then
      echo "No weekly full backup found in ${local.backup_minio_alias}/${local.backup_bucket}/${local.backup_path}/weekly/"
      exit 1
    fi
    # This keeps the weekly backup as the anchor and stores a daily binary delta
    # produced from a fresh pg_dumpall artifact rather than claiming native pg_dump incrementals.
    pg_dumpall --host="$POSTGRES_HOST" --port="$POSTGRES_PORT" --username="$POSTGRES_USERNAME" | gzip -9 > "$current_dump"
    mc cp "$latest_weekly" "$base_dump"
    rdiff delta "$base_dump" "$current_dump" "$delta_file"
    {
      echo "base_backup=$latest_weekly"
      echo "generated_at=$timestamp"
      echo "format=rdiff-delta"
    } > "$metadata_file"
    mc cp "$delta_file" "${local.backup_minio_alias}/${local.backup_bucket}/${local.backup_path}/daily/"
    mc cp "$metadata_file" "${local.backup_minio_alias}/${local.backup_bucket}/${local.backup_path}/daily/"
    mc rm --force --recursive --older-than "${local.backup_daily_retention}" "${local.backup_minio_alias}/${local.backup_bucket}/${local.backup_path}/daily/"
  EOT

  monthly_backup_script = <<-EOT
    set -euo pipefail
    ${local.backup_common_packages}
    ${local.backup_mc_install}
    timestamp="$(date -u '+%Y%m%dT%H%M%SZ')"
    backup_file="/tmp/${local.cluster_name}-monthly-${timestamp}.sql.gz"
    pg_dumpall --host="$POSTGRES_HOST" --port="$POSTGRES_PORT" --username="$POSTGRES_USERNAME" | gzip -9 > "$backup_file"
    mc cp "$backup_file" "${local.backup_minio_alias}/${local.backup_bucket}/${local.backup_path}/monthly/"
    mc rm --force --recursive --older-than "${local.backup_monthly_retention}" "${local.backup_minio_alias}/${local.backup_bucket}/${local.backup_path}/monthly/"
  EOT
}

resource "kubernetes_cron_job_v1" "weekly_backup" {
  count = local.backup_enabled ? 1 : 0

  metadata {
    name      = "${local.cluster_name}-weekly-backup"
    namespace = local.namespace
  }

  spec {
    schedule                      = local.backup_weekly_schedule
    concurrency_policy            = "Forbid"
    failed_jobs_history_limit     = 5
    successful_jobs_history_limit = 4
    starting_deadline_seconds     = 600

    job_template {
      spec {
        backoff_limit              = 1
        ttl_seconds_after_finished = 86400

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

            container {
              name    = "weekly-full-backup"
              image   = "${local.backup_image}:${local.backup_tag}"
              command = ["/bin/bash", "-ec", local.weekly_backup_script]

              env {
                name  = "POSTGRES_HOST"
                value = local.backup_host
              }

              env {
                name  = "POSTGRES_PORT"
                value = local.backup_port
              }

              env {
                name = "POSTGRES_USERNAME"
                value_from {
                  secret_key_ref {
                    name = local.root_secret_name
                    key  = "username"
                  }
                }
              }

              env {
                name = "PGPASSWORD"
                value_from {
                  secret_key_ref {
                    name = local.root_secret_name
                    key  = "password"
                  }
                }
              }

              env {
                name = "MINIO_ACCESS_KEY"
                value_from {
                  secret_key_ref {
                    name = local.backup_secret_name
                    key  = "access_key"
                  }
                }
              }

              env {
                name = "MINIO_SECRET_KEY"
                value_from {
                  secret_key_ref {
                    name = local.backup_secret_name
                    key  = "secret_key"
                  }
                }
              }

              env {
                name  = local.backup_mc_env
                value = local.backup_mc_host
              }
            }

            restart_policy = "Never"
          }
        }
      }
    }
  }

  depends_on = [
    helm_release.postgresql_ha,
    kubernetes_secret.root,
    kubernetes_secret.backup_minio,
  ]
}

resource "kubernetes_cron_job_v1" "daily_incremental_backup" {
  count = local.backup_enabled ? 1 : 0

  metadata {
    name      = "${local.cluster_name}-daily-incremental-backup"
    namespace = local.namespace
  }

  spec {
    schedule                      = local.backup_daily_schedule
    concurrency_policy            = "Forbid"
    failed_jobs_history_limit     = 7
    successful_jobs_history_limit = 7
    starting_deadline_seconds     = 600

    job_template {
      spec {
        backoff_limit              = 1
        ttl_seconds_after_finished = 86400

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

            container {
              name    = "daily-incremental-backup"
              image   = "${local.backup_image}:${local.backup_tag}"
              command = ["/bin/bash", "-ec", local.daily_incremental_script]

              env {
                name  = "POSTGRES_HOST"
                value = local.backup_host
              }

              env {
                name  = "POSTGRES_PORT"
                value = local.backup_port
              }

              env {
                name = "POSTGRES_USERNAME"
                value_from {
                  secret_key_ref {
                    name = local.root_secret_name
                    key  = "username"
                  }
                }
              }

              env {
                name = "PGPASSWORD"
                value_from {
                  secret_key_ref {
                    name = local.root_secret_name
                    key  = "password"
                  }
                }
              }

              env {
                name = "MINIO_ACCESS_KEY"
                value_from {
                  secret_key_ref {
                    name = local.backup_secret_name
                    key  = "access_key"
                  }
                }
              }

              env {
                name = "MINIO_SECRET_KEY"
                value_from {
                  secret_key_ref {
                    name = local.backup_secret_name
                    key  = "secret_key"
                  }
                }
              }

              env {
                name  = local.backup_mc_env
                value = local.backup_mc_host
              }
            }

            restart_policy = "Never"
          }
        }
      }
    }
  }

  depends_on = [
    helm_release.postgresql_ha,
    kubernetes_secret.root,
    kubernetes_secret.backup_minio,
    kubernetes_cron_job_v1.weekly_backup,
  ]
}

resource "kubernetes_cron_job_v1" "monthly_backup" {
  count = local.backup_enabled ? 1 : 0

  metadata {
    name      = "${local.cluster_name}-monthly-backup"
    namespace = local.namespace
  }

  spec {
    schedule                      = local.backup_monthly_schedule
    concurrency_policy            = "Forbid"
    failed_jobs_history_limit     = 6
    successful_jobs_history_limit = 6
    starting_deadline_seconds     = 600

    job_template {
      spec {
        backoff_limit              = 1
        ttl_seconds_after_finished = 86400

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

            container {
              name    = "monthly-full-backup"
              image   = "${local.backup_image}:${local.backup_tag}"
              command = ["/bin/bash", "-ec", local.monthly_backup_script]

              env {
                name  = "POSTGRES_HOST"
                value = local.backup_host
              }

              env {
                name  = "POSTGRES_PORT"
                value = local.backup_port
              }

              env {
                name = "POSTGRES_USERNAME"
                value_from {
                  secret_key_ref {
                    name = local.root_secret_name
                    key  = "username"
                  }
                }
              }

              env {
                name = "PGPASSWORD"
                value_from {
                  secret_key_ref {
                    name = local.root_secret_name
                    key  = "password"
                  }
                }
              }

              env {
                name = "MINIO_ACCESS_KEY"
                value_from {
                  secret_key_ref {
                    name = local.backup_secret_name
                    key  = "access_key"
                  }
                }
              }

              env {
                name = "MINIO_SECRET_KEY"
                value_from {
                  secret_key_ref {
                    name = local.backup_secret_name
                    key  = "secret_key"
                  }
                }
              }

              env {
                name  = local.backup_mc_env
                value = local.backup_mc_host
              }
            }

            restart_policy = "Never"
          }
        }
      }
    }
  }

  depends_on = [
    helm_release.postgresql_ha,
    kubernetes_secret.root,
    kubernetes_secret.backup_minio,
  ]
}
*/
