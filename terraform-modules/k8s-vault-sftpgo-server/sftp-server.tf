resource "helm_release" "sftp-server" {
  for_each     = var.server_list
  name         = "sftpgo-server-${each.key}"
  repository   = "https://charts.sagikazarmark.dev"
  chart        = "sftpgo"
  wait         = true
  atomic       = true
  namespace    = try(each.value.namespace, local.namespace)
  version      = var.sftpgo_version
  reset_values = true
  set {
    name  = "fullnameOverride"
    value = "sftp-server-${each.key}"
  }
  set {
    name  = "image.tag"
    value = "edge"
  }
  set {
    name  = "volumes[0].name"
    value = "host-keys"
  }
  set {
    name  = "volumes[0].configMap.name"
    value = "sftp-server-${each.key}-host-keys"
  }
  set {
    name  = "volumes[1].name"
    value = "sftp-config"
  }
  set {
    name  = "volumes[1].configMap.name"
    value = "sftp-server-${each.key}-config"
  }
  set {
    name  = "volumeMounts[0].mountPath"
    value = "/var/lib/sftpgo/id_ed25519"
  }
  set {
    name  = "volumeMounts[0].subPath"
    value = "id_ed25519"
  }
  set {
    name  = "volumeMounts[0].name"
    value = "host-keys"
  }
  set {
    name  = "volumeMounts[1].mountPath"
    value = "/var/lib/sftpgo/id_ed25519.pub"
  }
  set {
    name  = "volumeMounts[1].subPath"
    value = "id_ed25519.pub"
  }
  set {
    name  = "volumeMounts[1].name"
    value = "host-keys"
  }
  set {
    name  = "volumeMounts[2].mountPath"
    value = "/var/lib/sftpgo/id_rsa"
  }
  set {
    name  = "volumeMounts[2].subPath"
    value = "id_rsa"
  }
  set {
    name  = "volumeMounts[2].name"
    value = "host-keys"
  }
  set {
    name  = "volumeMounts[3].mountPath"
    value = "/var/lib/sftpgo/id_rsa.pub"
  }
  set {
    name  = "volumeMounts[3].subPath"
    value = "id_rsa.pub"
  }
  set {
    name  = "volumeMounts[3].name"
    value = "host-keys"
  }
  set {
    name  = "volumeMounts[4].name"
    value = "sftp-config"
  }
  set {
    name  = "volumeMounts[4].mountPath"
    value = "/var/lib/sftpgo/config.json"
  }
  set {
    name  = "volumeMounts[4].subPath"
    value = "config.json"
  }
  set {
    name  = "env.SFTPGO_LOADDATA_FROM"
    value = "/var/lib/sftpgo/config.json"
  }
  set {
    name  = "env.SFTPGO_DATA_PROVIDER__DRIVER"
    value = "postgresql"
  }
  set {
    name  = "env.SFTPGO_DATA_PROVIDER__NAME"
    value = "sftpgo"
  }
  set {
    name  = "env.SFTPGO_DATA_PROVIDER__HOST"
    value = "gitlab-postgresql.gitlab.svc"
  }
  set {
    name  = "env.SFTPGO_DATA_PROVIDER__PORT"
    value = "5432"
  }
  set {
    name  = "env.SFTPGO_DATA_PROVIDER__USERNAME"
    value = data.vault_generic_secret.db_creds["${each.key}"].data["username"]
  }
  #set {
  #  name  = "env.SFTPGO_DATA_PROVIDER__PASSWORD"
  #  value = "$POSTGRES_PASSWORD" #data.vault_generic_secret.db-creds["${each.key}"].data["password"]
  #}
  set {
    name  = "envVars[0].name"
    value = "SFTPGO_DATA_PROVIDER__PASSWORD"
  }
  set {
    name  = "envVars[0].valueFrom.secretKeyRef.name"
    value = "sftp-server-${each.key}-db-creds"
  }
  set {
    name  = "envVars[0].valueFrom.secretKeyRef.key"
    value = "POSTGRES_PASSWORD"
  }

  depends_on = [kubernetes_config_map.ssh_host_keys ,vault_generic_secret.admin_user_config, kubernetes_secret.db_creds]
}

### Postrgesql credentials
data "vault_generic_secret" "db_creds" {
  for_each     = var.server_list
  path         = "secret/sftp-server/${each.key}-db-creds"
}

resource "kubernetes_secret" "db_creds" {
  for_each     = var.server_list
  metadata {
    name       = "sftp-server-${each.key}-db-creds"
    namespace  = try(each.value.namespace, local.namespace)
  }
  data = {
    "PGPASSWORD" = data.vault_generic_secret.db_creds["${each.key}"].data["password"]
  }
}

data "vault_generic_secret" "minio_creds" {
  path         = "secret/minio/users"
}

resource "kubernetes_secret" "minio_creds" {
  for_each     = {"${local.minio_user}":{}}
  metadata {
    name       = "sftp-server-main-minio-creds"
    namespace  = try(each.value.namespace, local.namespace)
  }
  data = {
    AWS_ACCESS_KEY_ID = jsondecode(data.vault_generic_secret.minio_creds.data[each.key]).accessKey,
    AWS_SECRET_ACCESS_KEY = jsondecode(data.vault_generic_secret.minio_creds.data[each.key]).secretKey
  }
}

### Mount host keys
data "vault_generic_secret" "ssh_host_keys" {
  for_each = var.server_list
  path         = "secret/sftp-server/${each.key}-host-keys"
}

resource "kubernetes_config_map" "ssh_host_keys" {
  for_each = var.server_list
  metadata {
    name       = "sftp-server-${each.key}-host-keys"
    namespace  = try(each.value.namespace, local.namespace)
  }

  data = data.vault_generic_secret.ssh_host_keys[each.key].data
}

### INIT ADMIN USER FOR SFTPGO PROVIDER CONNECTION

data "vault_generic_secret" "sftp_admin" {
  path         = "secret/sftp-server/admin"
}

resource "vault_generic_secret" "admin_user_config" {
  path = "secret/sftp-server/init-admin-user"

  data_json = jsonencode({"config.json":"${templatefile("${path.module}/config.json", { PASSWORD = bcrypt(data.vault_generic_secret.sftp_admin.data["password"]) })}"})
}

data "vault_generic_secret" "config" {
  for_each = var.server_list
  path         = "secret/sftp-server/init-admin-user"

  depends_on = [vault_generic_secret.admin_user_config]
}
resource "kubernetes_config_map" "config" {
  for_each = var.server_list
  metadata {
    name       = "sftp-server-${each.key}-config"
    namespace  = try(each.value.namespace, local.namespace)
  }

  data = data.vault_generic_secret.config[each.key].data
}


resource "kubernetes_cron_job" "database_backup" {
  for_each = var.server_list
  metadata {
    name = "${local.server_name}-${each.key}-db-backup-cronjob"
    namespace = try(each.value.namespace, local.namespace)
  }
  spec {
    schedule = "0 * * * *"
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
              "sidecar.istio.io/inject": "false"
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
                value = "sftpgo"
              }
              env {
                name  = "POSTGRES_USERNAME"
                value = "sftpgo"
              }
              env {
                name  = "POSTGRES_HOST"
                value = "gitlab-postgresql.gitlab.svc"
              }
              env {
                name  = "POSTGRES_PORT"
                value = "5432"
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
                value = "minio-sftpgo-orbital-wording"
              }
              env {
                name  = "MINIO_HOST"
                value = "https://minio.p.regemini.io"
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