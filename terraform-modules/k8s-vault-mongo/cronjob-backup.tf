locals {
  backupCommand = <<EOT
set -e;
apt-get update -q && apt-get install wget -yq ;
wget --quiet https://dl.min.io/client/mc/release/linux-amd64/mc ;
chmod +x mc ;
source /vault/secrets/config ;
date_time=`date '+%Y%m%d-%H:%M:%S'`;
./mc rm --force --recursive --older-than 30d backup/${var.BackupBucket}/mongod-backup/${var.MongoNs}/;
%{for setting in var.BackupSettings}
%{if setting.encrypt}
mongodump --gzip --archive --uri=$MONGODB_URL --db ${setting.dbName} | gpg -r Backup  --armor  --encrypt| ./mc pipe backup/${var.BackupBucket}/mongod-backup/${var.MongoNs}/${setting.dbName}/${setting.dbName}-$date_time.gpg ;
%{else}
mongodump --gzip --archive --uri=$MONGODB_URL --db ${setting.dbName} | ./mc pipe backup/${var.BackupBucket}/mongod-backup/${var.MongoNs}/${setting.dbName}/${setting.dbName}-$date_time.gz ;
%{endif}
%{endfor}
EOT
}

resource "random_id" "rand" {
  byte_length = 8
}

resource "kubernetes_cron_job_v1" "mongo_backup" {
  metadata {
    name      = "mongo-backup"
    namespace = var.MongoNs
  }
  spec {
    concurrency_policy            = "Replace"
    failed_jobs_history_limit     = 5
    schedule                      = "1 0 * * *"
    starting_deadline_seconds     = 120
    successful_jobs_history_limit = 120
    job_template {
      metadata {}
      spec {
        backoff_limit = 1
        template {
          metadata {
            annotations = {
              "sidecar.istio.io/inject"                          = "false"
              "vault.hashicorp.com/agent-inject"                 = "true"
              "vault.hashicorp.com/agent-inject-secret-config"   = "secret/data/backup/gpg"
              "vault.hashicorp.com/role"                         = var.MongoNs
              "vault.hashicorp.com/agent-pre-populate-only"      = "true"
              "vault.hashicorp.com/auth-path"                    = "auth/k8s-${var.Cluster}-${var.Color}"
              "vault.hashicorp.com/agent-inject-template-config" = <<EOT
                {{ with secret "secret/data/backup/gpg" -}}
                  echo "{{.Data.data.key}}" | base64 -d | gpg --import
                  echo "{{.Data.data.ownertrust}}" | gpg --import-ownertrust
                  echo "GPG settings imported successfully"
                {{- end }}
EOT
            }
          }
          spec {
            container {
              name    = "dump"
              image   = "mongo"
              command = ["bash", "-c", local.backupCommand]
              env {
                name = "MINIO_ACCESS_KEY"
                value_from {
                  secret_key_ref {
                    name = "minio-credentials"
                    key  = "accesskey"
                  }
                }
              }
              env {
                name = "MINIO_SECRET_KEY"
                value_from {
                  secret_key_ref {
                    name = "minio-credentials"
                    key  = "secretkey"
                  }
                }
              }
              env {
                name  = "MC_HOST_backup"
                value = "http://$(MINIO_ACCESS_KEY):$(MINIO_SECRET_KEY)@minio.minio:9000"
              }
              env {
                name = "MONGO_USER"
                value_from {
                  secret_key_ref {
                    name = "mongo"
                    key  = "MONGODB_BACKUP_USER"
                  }
                }
              }
              env {
                name = "MONGO_PASS"
                value_from {
                  secret_key_ref {
                    name = "mongo"
                    key  = "MONGODB_BACKUP_PASSWORD"
                  }
                }
              }
              env {
                name  = "MONGODB_URL"
                value = "mongodb://$(MONGO_USER):$(MONGO_PASS)@${local.full_name}-rs0:27017/?ssl=false&authSource=admin&readPreference=primaryPreferred&replicaSet=rs0"
              }
            }
          }
        }
      }
    }
  }
}
