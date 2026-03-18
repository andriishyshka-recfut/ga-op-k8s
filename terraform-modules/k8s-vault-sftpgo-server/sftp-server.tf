resource "helm_release" "sftp-server" {
  for_each     = var.server_list
  name         = "sftpgo-server-${each.key}"
  repository   = "https://charts.sagikazarmark.dev"
  chart        = "sftpgo"
  wait         = true
  atomic       = true
  namespace    = try(each.value.namespace, local.namespace)
  version      = local.chart_version
  reset_values = true
  values = [
    templatefile("${path.module}/templates/sftp.tftpl",{
      name = each.key
      values = merge(local.default_values, each.value)
      vaultValues = data.vault_generic_secret.db_creds["${each.key}"].data
    })
  ]

  depends_on = [kubernetes_config_map.ssh_host_keys, kubernetes_config_map.config, kubernetes_secret.db_creds]
}

### Postrgesql credentials
data "vault_generic_secret" "db_creds" {
  for_each = var.server_list
  path     = "secret/sftp-server/${each.key}-db-creds"
}

resource "kubernetes_secret" "db_creds" {
  for_each = var.server_list
  metadata {
    name      = "sftp-server-${each.key}-db-creds"
    namespace = try(each.value.namespace, local.namespace)
  }
  data = {
    "PGPASSWORD" = data.vault_generic_secret.db_creds["${each.key}"].data["password"]
  }
}
#I'm not sure that we use this
data "vault_generic_secret" "minio_creds" {
  path = "secret/minio/users"
}


resource "kubernetes_secret" "minio_creds" {
  for_each = { "${local.minio_user}" : {} }
  metadata {
    name      = "sftp-server-main-minio-creds"
    namespace = try(each.value.namespace, local.namespace)
  }
  data = {
    AWS_ACCESS_KEY_ID     = jsondecode(data.vault_generic_secret.minio_creds.data[each.key]).accessKey,
    AWS_SECRET_ACCESS_KEY = jsondecode(data.vault_generic_secret.minio_creds.data[each.key]).secretKey
  }
}

#CA from minio
data "vault_pki_secret_backend_issuer" "pki_minio" {
  backend    = "pki-minio"
  issuer_ref = "default"
}
resource "kubernetes_secret" "minio_ca_cert" {
  metadata {
    name      = "minio-ca-certs"
    namespace = local.namespace
  }
  data = {
    "ca.crt" = data.vault_pki_secret_backend_issuer.pki_minio.certificate
  }
  depends_on = [data.vault_pki_secret_backend_issuer.pki_minio]
}
### Mount host keys
data "vault_generic_secret" "ssh_host_keys" {
  for_each = var.server_list
  path     = "secret/sftp-server/${each.key}-host-keys"
}

resource "kubernetes_config_map" "ssh_host_keys" {
  for_each = var.server_list
  metadata {
    name      = "sftp-server-${each.key}-host-keys"
    namespace = try(each.value.namespace, local.namespace)
  }

  data = data.vault_generic_secret.ssh_host_keys[each.key].data
}

### INIT ADMIN USER FOR SFTPGO PROVIDER CONNECTION

data "vault_generic_secret" "sftp_admin" {
  path = "secret/sftp-server/admin"
}

resource "kubernetes_config_map" "config" {
  for_each = var.server_list
  metadata {
    name      = "sftp-server-${each.key}-config"
    namespace = try(each.value.namespace, local.namespace)
  }

  data = {
    "config.json" = "${templatefile("${path.module}/config.json", { PASSWORD = bcrypt(data.vault_generic_secret.sftp_admin.data["password"]) })}"
  }
}

/*
resource "kubernetes_config_map" "sftpgo" {
  for_each = var.server_list
  metadata {
    name       = "sftpgo-${each.key}-config"
    namespace  = try(each.value.namespace, local.namespace)
  }

  data = {
    "sftpgo.json" = file("${path.module}/sftpgo.json")
  }
}*/

resource "kubernetes_cron_job_v1" "database_backup" {
  for_each = var.server_list
  metadata {
    name      = "${local.server_name}-${each.key}-db-backup-cronjob"
    namespace = try(each.value.namespace, local.namespace)
  }
  spec {
    schedule                      = "0 0 * * *"
    concurrency_policy            = "Replace"
    failed_jobs_history_limit     = 5
    starting_deadline_seconds     = 10
    successful_jobs_history_limit = 10
    job_template {
      metadata {
        #generate_name = "${local.server_name}-db-backup-job-"
      }
      spec {
        backoff_limit              = 2
        ttl_seconds_after_finished = 10
        template {
          metadata {
            annotations = {
              "sidecar.istio.io/inject" : "false"
            }
          }
          spec {
            image_pull_secrets {
              name = "harbor"
            }
            container {
              name    = "minio-pgdump"
              image   = "harbor.regemini.io/op/postgres-minio-backup:1"
              command = ["/bin/sh", "-c", "pg_dump -p $POSTGRES_PORT -U $POSTGRES_USERNAME -d $POSTGRES_DB_NAME -h $POSTGRES_HOST > $BACKUP_NAME-$(date '+%Y-%m-%dT%H').sql && aws s3 --endpoint $MINIO_HOST cp $BACKUP_NAME-$(date '+%Y-%m-%dT%H').sql s3://$MINIO_BUCKET/postgres-dump/"]
              env {
                name  = "POSTGRES_DB_NAME"
                value = data.vault_generic_secret.db_creds["${each.key}"].data["db_name"]
              }
              env {
                name  = "POSTGRES_USERNAME"
                value = data.vault_generic_secret.db_creds["${each.key}"].data["username"]
              }
              env {
                name  = "POSTGRES_HOST"
                value = try(each.value.postgres_url, local.postgres_url)
              }
              env {
                name  = "POSTGRES_PORT"
                value = local.postgres_port
              }
              env_from {
                secret_ref {
                  name = "sftp-server-${each.key}-db-creds"
                }
              }
              env {
                name  = "BACKUP_NAME"
                value = "/tmp/sftgo-db-dump"
              }
              env {
                name  = "MINIO_BUCKET"
                value = try(each.value.minio_bucket, local.minio_bucket)
              }
              env {
                name  = "MINIO_HOST"
                value = try(each.value.minio_url, local.minio_url)
              }
              env_from {
                secret_ref {
                  name = "sftp-server-${each.key}-minio-creds"
                }
              }
            }
          }
        }
      }
    }
  }
}
