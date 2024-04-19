locals {
  restoreCommand = <<EOT
set -e;
set +x ;
apt-get update -q && apt-get install wget gpg -yq ;
wget --quiet https://dl.min.io/client/mc/release/linux-amd64/mc ;
chmod +x mc ;
source /vault/secrets/config ;
cd /data;
%{for setting in var.BackupSettings}
%{if setting.encrypt}
/mc cp  backup/${var.BackupBucket}/mongod-backup/mongo/${setting.dbName}.gpg ${setting.dbName}.gpg;
gpg -r Backup   -o ${setting.dbName}.tar.gz --decrypt ${setting.dbName}.gpg ;
%{else}
bcp_file=$(/mc find backup/${var.BackupBucket}/mongod-backup/mongo/${setting.dbName} --name "*${local.restore_date}*.gz" | sort -n | tail -1);
/mc cp  $bcp_file ${setting.dbName}.tar.gz;
%{endif}
mongorestore --archive="${setting.dbName}.tar.gz" --gzip --uri=$MONGODB_URL --db ${setting.dbName} ;
%{endfor}

EOT
}
resource "random_id" "rand" {
  byte_length = 8
}

resource "kubernetes_persistent_volume_claim" "volume" {
  metadata {
    name      = "restore-${lower(random_id.rand.hex)}"
    namespace = var.MongoNs
  }
  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "kms-encrypted"
    resources {
      requests = {
        storage = "200Gi"
      }
    }
  }
}


resource "kubernetes_job" "mongo_restore" {
  metadata {
    name      = "mongo-restore-${lower(random_id.rand.hex)}"
    namespace = var.MongoNs
  }
  spec {
    ttl_seconds_after_finished = 270000
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
                    {{ with secret "secret/backup/gpg" -}}
                      echo "{{.Data.data.key}}" | base64 -d | gpg --import
                      echo "{{.Data.data.ownertrust}}" | gpg --import-ownertrust
                    {{- end }}
EOT
        }
      }
      spec {
        # node_selector = {
        #   workloadsType =  "data"
        # }
        # toleration {
        #    key =  "workloadsType"
        #     operator = "Exists"
        #     effect= "NoSchedule"
        #   }
        volume {
          name = "data"
          persistent_volume_claim {
            claim_name = "restore-${lower(random_id.rand.hex)}"
          }
        }
        container {
          name    = "restore"
          image   = "harbor.regemini.io/op/mongo-backup:7.0.5"
          command = ["bash", "-c", local.restoreCommand]
          volume_mount {
            name       = "data"
            mount_path = "/data"
          }
          resources {
            limits = {
              cpu    = 1
              memory = "2Gi"
            }
            requests = {
              cpu    = 0.1
              memory = "256Mi"
            }
          }
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
            name  = "RESTORE_DATE"
            value = local.restore_date
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
            value = "mongodb://$(MONGO_USER):$(MONGO_PASS)@mongo-main-rs0:27017/?ssl=false&authSource=admin&readPreference=primaryPreferred&replicaSet=rs0"
          }
        }
        image_pull_secrets {
          name = "harbor"
        }
        restart_policy = "Never"
      }
    }

    backoff_limit = 0
  }
  wait_for_completion = false
  timeouts {
    create = "1200m"
    update = "1200m"
  }
}
