resource "random_id" "rand" {
  byte_length = 8
}

resource "kubernetes_job" "redis_backup" {
  for_each = var.BackupSettings
  metadata {
    name      = "redis-backup-${lower(random_id.rand.hex)}"
    namespace = each.value["ns"]
  }
  spec {
    template {
      metadata {
        annotations = {
          "sidecar.istio.io/inject" = "false"
        }
      }
      spec {
        container {
          name    = "redis-dump"
          image   = "redisrdbcli/redis-rdb-cli"
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
            name  = "BACKUP_SERVICE_NAME"
            value = each.value["service"]
          }
          env {
            name  = "BACKUP_SERVICE_PORT"
            value = each.value["port"]
          }
          env {
            name  = "BACKUP_NAME"
            value = each.value["name"]
          }
          env {
            name  = "SENTINEL"
            value = each.value["sentinel"] ? "yes" : "no"
          }
        }
        restart_policy = "Never"
      }
    }

    backoff_limit = 1
  }
  wait_for_completion = true
  timeouts {
    create = "10m"
    update = "10m"
  }
  # depends_on = [kubernetes_secret.minio_backup_redis_credentials]
}
