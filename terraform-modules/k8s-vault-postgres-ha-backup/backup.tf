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
  backup_s3_prefix      = "s3://${local.backup_bucket}/${local.backup_path}"
  backup_mc_prefix      = "${local.backup_minio_alias}/${local.backup_bucket}/${local.backup_path}"
  backup_mc_env         = "MC_HOST_${replace(upper(local.backup_minio_alias), "-", "_")}"
  backup_mc_host        = startswith(local.backup_minio_endpoint, "https://") ? "https://$(MINIO_ACCESS_KEY):$(MINIO_SECRET_KEY)@${trimsuffix(trimprefix(local.backup_minio_endpoint, "https://"), "/")}" : "http://$(MINIO_ACCESS_KEY):$(MINIO_SECRET_KEY)@${trimsuffix(trimprefix(local.backup_minio_endpoint, "http://"), "/")}"
  backup_cluster_remote = local.backup_cli == "mc" ? "${local.backup_mc_prefix}/cluster/" : "${local.backup_s3_prefix}/cluster/"
  backup_globals_remote = local.backup_cli == "mc" ? "${local.backup_mc_prefix}/" : "${local.backup_s3_prefix}/"

  backup_cli_helpers_mc = <<-EOT
    command -v mc >/dev/null 2>&1 || { echo "mc CLI is not installed in the backup image"; exit 1; }
    backup_upload() {
      mc cp "$1" "$2"
    }
    backup_prune_by_age() {
      mc rm --force --recursive --older-than "$2" "$1"
    }
    backup_prune_named_by_age() {
      local remote_prefix="$$1"
      local file_prefix="$$2"
      local file_suffix="$$3"
      local retention="$$4"
      local days="$${retention%d}"
      local cutoff
      cutoff="$$(date -u -d "-$${days} days" '+%Y%m%dT%H%M%SZ')"
      mc find "$$remote_prefix" | while read -r object_path; do
        [ -z "$$object_path" ] && continue
        local filename
        local timestamp
        filename="$$(basename "$$object_path")"
        case "$$filename" in
          "$${file_prefix}"*"$${file_suffix}")
            timestamp="$$(printf '%s\n' "$$filename" | grep -oE '[0-9]{8}T[0-9]{6}Z' | tail -1 || true)"
            if [ -n "$$timestamp" ] && [ "$$timestamp" \< "$$cutoff" ]; then
              mc rm "$$object_path"
            fi
            ;;
        esac
      done
    }
  EOT

  backup_cli_helpers_aws = <<-EOT
    command -v aws >/dev/null 2>&1 || { echo "aws CLI is not installed in the backup image"; exit 1; }
    backup_upload() {
      aws --endpoint-url "$MINIO_ENDPOINT" s3 cp "$1" "$2"
    }
    backup_prune_by_age() {
      local remote_prefix="$$1"
      local retention="$$2"
      local days="$${retention%d}"
      local cutoff
      cutoff="$$(date -u -d "-$${days} days" '+%Y%m%dT%H%M%SZ')"
      aws --endpoint-url "$MINIO_ENDPOINT" s3 ls "$$remote_prefix" | awk '{print $$4}' | while read -r name; do
        [ -z "$$name" ] && continue
        timestamp="$$(printf '%s\n' "$$name" | grep -oE '[0-9]{8}T[0-9]{6}Z' | tail -1 || true)"
        if [ -n "$$timestamp" ] && [ "$$timestamp" \< "$$cutoff" ]; then
          aws --endpoint-url "$MINIO_ENDPOINT" s3 rm "$$remote_prefix$$name"
        fi
      done
    }
    backup_prune_named_by_age() {
      local remote_prefix="$$1"
      local file_prefix="$$2"
      local file_suffix="$$3"
      local retention="$$4"
      local days="$${retention%d}"
      local cutoff
      cutoff="$$(date -u -d "-$${days} days" '+%Y%m%dT%H%M%SZ')"
      aws --endpoint-url "$MINIO_ENDPOINT" s3 ls "$$remote_prefix" | awk '{print $$4}' | while read -r name; do
        [ -z "$$name" ] && continue
        local timestamp
        case "$$name" in
          "$${file_prefix}"*"$${file_suffix}")
            timestamp="$$(printf '%s\n' "$$name" | grep -oE '[0-9]{8}T[0-9]{6}Z' | tail -1 || true)"
            if [ -n "$$timestamp" ] && [ "$$timestamp" \< "$$cutoff" ]; then
              aws --endpoint-url "$MINIO_ENDPOINT" s3 rm "$$remote_prefix$$name"
            fi
            ;;
        esac
      done
    }
  EOT

  backup_cli_helpers = local.backup_cli == "mc" ? local.backup_cli_helpers_mc : local.backup_cli_helpers_aws

  cluster_backup_script = <<-EOT
    set -euo pipefail
    command -v pg_dumpall >/dev/null 2>&1 || { echo "pg_dumpall is not installed in the backup image"; exit 1; }
    command -v gzip >/dev/null 2>&1 || { echo "gzip is not installed in the backup image"; exit 1; }
    ${local.backup_cli_helpers}
    timestamp="$(date -u '+%Y%m%dT%H%M%SZ')"
    backup_file="/tmp/${local.cluster_name}-$${timestamp}.sql.gz"
    pg_dumpall --host="$POSTGRES_HOST" --port="$POSTGRES_PORT" --username="$POSTGRES_USERNAME" | gzip -9 > "$backup_file"
    backup_upload "$backup_file" "${local.backup_cluster_remote}"
    backup_prune_by_age "${local.backup_cluster_remote}" "${local.backup_retention}"
  EOT

  globals_backup_script = <<-EOT
    set -euo pipefail
    command -v pg_dumpall >/dev/null 2>&1 || { echo "pg_dumpall is not installed in the backup image"; exit 1; }
    ${local.backup_cli_helpers}
    timestamp="$(date -u '+%Y%m%dT%H%M%SZ')"
    backup_file="/tmp/globals-$${timestamp}.sql"
    pg_dumpall --host="$POSTGRES_HOST" --port="$POSTGRES_PORT" --username="$POSTGRES_USERNAME" --globals-only > "$backup_file"
    backup_upload "$backup_file" "${local.backup_globals_remote}"
    backup_prune_named_by_age "${local.backup_globals_remote}" "globals-" ".sql" "${local.backup_retention}"
  EOT

  database_backup_jobs = {
    for db in local.backup_databases : db => {
      database = db
      remote   = local.backup_cli == "mc" ? "${local.backup_mc_prefix}/databases/${db}/" : "${local.backup_s3_prefix}/databases/${db}/"
      resource_name = substr(
        "${substr(join("-", regexall("[a-z0-9]+", lower(local.cluster_name))), 0, 18)}-${substr(join("-", regexall("[a-z0-9]+", lower(db))), 0, 18)}-backup-${substr(sha1(db), 0, 6)}",
        0,
        63
      )
      script = <<-EOT
        set -euo pipefail
        command -v pg_dump >/dev/null 2>&1 || { echo "pg_dump is not installed in the backup image"; exit 1; }
        command -v psql >/dev/null 2>&1 || { echo "psql is not installed in the backup image"; exit 1; }
        ${local.backup_cli_helpers}
        timestamp="$(date -u '+%Y%m%dT%H%M%SZ')"
        backup_file="/tmp/${db}-$${timestamp}.dump"
        owner_file="/tmp/${db}-$${timestamp}.owner"
        grants_file="/tmp/${db}-$${timestamp}.grants.sql"
        pg_dump --host="$POSTGRES_HOST" --port="$POSTGRES_PORT" --username="$POSTGRES_USERNAME" --dbname="${db}" --format=custom --compress=9 --file="$backup_file"
        psql -At -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USERNAME" -d postgres -c "SELECT pg_catalog.quote_ident(r.rolname) FROM pg_database d JOIN pg_roles r ON r.oid = d.datdba WHERE d.datname = '${db}'" > "$owner_file"
        if [ ! -s "$owner_file" ]; then
          echo "Unable to determine owner for database ${db}"
          exit 1
        fi
        psql -At -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USERNAME" -d postgres -c "WITH acl_entries AS (SELECT a.grantee, a.privilege_type FROM pg_database d CROSS JOIN LATERAL aclexplode(COALESCE(d.datacl, acldefault('d', d.datdba))) AS a WHERE d.datname = '${db}'), grant_statements AS (SELECT DISTINCT format('GRANT %s ON DATABASE \"__RESTORE_TARGET_DB__\" TO %s;', privilege_type, CASE WHEN grantee = 0 THEN 'PUBLIC' ELSE pg_catalog.quote_ident((SELECT rolname FROM pg_roles WHERE oid = grantee)) END) AS stmt FROM acl_entries) SELECT stmt FROM grant_statements ORDER BY stmt;" > "$grants_file"
        backup_upload "$backup_file" "${local.backup_cli == "mc" ? "${local.backup_mc_prefix}/databases/${db}/" : "${local.backup_s3_prefix}/databases/${db}/"}"
        backup_upload "$owner_file" "${local.backup_cli == "mc" ? "${local.backup_mc_prefix}/databases/${db}/" : "${local.backup_s3_prefix}/databases/${db}/"}"
        backup_upload "$grants_file" "${local.backup_cli == "mc" ? "${local.backup_mc_prefix}/databases/${db}/" : "${local.backup_s3_prefix}/databases/${db}/"}"
        backup_prune_by_age "${local.backup_cli == "mc" ? "${local.backup_mc_prefix}/databases/${db}/" : "${local.backup_s3_prefix}/databases/${db}/"}" "${local.backup_retention}"
      EOT
    }
  }
}

resource "kubernetes_cron_job_v1" "cluster_backup" {
  count = local.backup_enabled ? 1 : 0

  metadata {
    name      = "${local.cluster_name}-cluster-backup"
    namespace = local.namespace
  }

  spec {
    schedule                      = local.backup_schedule
    concurrency_policy            = "Forbid"
    failed_jobs_history_limit     = 7
    successful_jobs_history_limit = 7
    starting_deadline_seconds     = 600

    job_template {
      metadata {}

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
              name    = "cluster-backup"
              image   = "${local.backup_image}:${local.backup_tag}"
              command = ["/bin/bash", "-ec", local.cluster_backup_script]

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

              env {
                name = "AWS_ACCESS_KEY_ID"
                value_from {
                  secret_key_ref {
                    name = local.backup_secret_name
                    key  = "access_key"
                  }
                }
              }

              env {
                name = "AWS_SECRET_ACCESS_KEY"
                value_from {
                  secret_key_ref {
                    name = local.backup_secret_name
                    key  = "secret_key"
                  }
                }
              }

              env {
                name  = "MINIO_ENDPOINT"
                value = local.backup_minio_endpoint
              }
            }

            restart_policy = "Never"
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_secret.backup_minio,
  ]
}

resource "kubernetes_cron_job_v1" "globals_backup" {
  count = local.backup_enabled && local.backup_globals_enabled ? 1 : 0

  metadata {
    name      = "${local.cluster_name}-globals-backup"
    namespace = local.namespace
  }

  spec {
    schedule                      = local.backup_schedule
    concurrency_policy            = "Forbid"
    failed_jobs_history_limit     = 7
    successful_jobs_history_limit = 7
    starting_deadline_seconds     = 600

    job_template {
      metadata {}

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
              name    = "globals-backup"
              image   = "${local.backup_image}:${local.backup_tag}"
              command = ["/bin/bash", "-ec", local.globals_backup_script]

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

              env {
                name = "AWS_ACCESS_KEY_ID"
                value_from {
                  secret_key_ref {
                    name = local.backup_secret_name
                    key  = "access_key"
                  }
                }
              }

              env {
                name = "AWS_SECRET_ACCESS_KEY"
                value_from {
                  secret_key_ref {
                    name = local.backup_secret_name
                    key  = "secret_key"
                  }
                }
              }

              env {
                name  = "MINIO_ENDPOINT"
                value = local.backup_minio_endpoint
              }
            }

            restart_policy = "Never"
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_secret.backup_minio,
  ]
}

resource "kubernetes_cron_job_v1" "database_full_backup" {
  for_each = local.backup_enabled ? local.database_backup_jobs : {}

  metadata {
    name      = each.value.resource_name
    namespace = local.namespace
  }

  spec {
    schedule                      = local.backup_schedule
    concurrency_policy            = "Forbid"
    failed_jobs_history_limit     = 7
    successful_jobs_history_limit = 7
    starting_deadline_seconds     = 600

    job_template {
      metadata {}

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
              name    = "database-backup"
              image   = "${local.backup_image}:${local.backup_tag}"
              command = ["/bin/bash", "-ec", each.value.script]

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

              env {
                name = "AWS_ACCESS_KEY_ID"
                value_from {
                  secret_key_ref {
                    name = local.backup_secret_name
                    key  = "access_key"
                  }
                }
              }

              env {
                name = "AWS_SECRET_ACCESS_KEY"
                value_from {
                  secret_key_ref {
                    name = local.backup_secret_name
                    key  = "secret_key"
                  }
                }
              }

              env {
                name  = "MINIO_ENDPOINT"
                value = local.backup_minio_endpoint
              }
            }

            restart_policy = "Never"
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_secret.backup_minio,
  ]
}
