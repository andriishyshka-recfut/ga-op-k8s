locals {
  restoreCommand = <<EOT
set -e;
apt-get update -q && apt-get install wget -yq ;
wget --quiet https://dl.min.io/client/mc/release/linux-amd64/mc ;
chmod +x mc ;
/mc cp  backup/minio-xbackup-${local.currentProject}/mongod-backup/artifact.tar artifact.tar.gz;
mongorestore --archive="artifact.tar.gz" --gzip --uri=$MONGODB_URL --db artifact ;
EOT
}

resource "kubernetes_job" "mongo_restore" {

  metadata {
    name      = "mongo-restore"
    namespace = local.mongoNs
  }
  spec {
    ttl_seconds_after_finished = 270000
    template {
      metadata {
        annotations = {
          "sidecar.istio.io/inject" = "false"
        }
      }
      spec {
        container {
          name    = "restore"
          image   = "mongo"
          command = ["bash", "-c", local.restoreCommand]
          resources {
            limits = {
              cpu = 2
              memory = "2Gi"
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
            value = "mongodb://$(MONGO_USER):$(MONGO_PASS)@my-cluster-name-rs0-0:27017,my-cluster-name-rs0-1:27017,my-cluster-name-rs0-2:27017/?ssl=false&authSource=admin&readPreference=primaryPreferred&replicaSet=rs0"
          }
        }
        restart_policy = "Never"
      }
    }

    backoff_limit = 1
  }
  wait_for_completion = true
  timeouts {
    create = "120m"
    update = "120m"
  }
}
