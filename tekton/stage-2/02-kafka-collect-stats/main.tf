locals {
  namespace   = "kafka"
  bucket_name = var.Cluster == "production" ? "minio-kafka-backups-orbital-wording-233917" : "minio-kafka-backups-ardent-rarity-239115"
}


# data "vault_generic_secret" "minio_creds" {
#   path = "secret/mw/kafka/kafka-checker/minio"
# }


# resource "kubernetes_secret" "minio_creds" {
#   metadata {
#     name      = "minio-credentials"
#     namespace = local.namespace
#   }
#   data = {
#     ACCESS_KEY = data.vault_generic_secret.minio_creds.data.ACCESS_KEY
#     SECRET_KEY = data.vault_generic_secret.minio_creds.data.SECRET_KEY
#   }
# }



resource "kubernetes_job" "kafka_collect_stats" {
  wait_for_completion = false
  metadata {
    name      = "pre-switch-kafka-check"
    namespace = "kafka"
    labels = {
      app                       = "kafka-check-stats"
      "sidecar.istio.io/inject" = "false"
    }
  }

  spec {
    template {
      metadata {
        labels = {
          app                       = "kafka-check-stats"
          "sidecar.istio.io/inject" = "false"
        }
      }

      spec {
        container {
          name              = "kafka-checker"
          image             = "${local.artifactoryRepoDomain}/ga-op-docker-local/kafka-checker:v0.0.1"
          image_pull_policy = "Always"
          command           = ["sh", "-c", "./before_switch.sh"]
          # command = ["tail", "-f", "/dev/null"]

          env {
            name = "MINIO_ACCESS_KEY"
            value_from {
              secret_key_ref {
                name = "minio-credentials"
                key  = "ACCESS_KEY"
              }
            }
          }
          env {
            name = "MINIO_SECRET_KEY"
            value_from {
              secret_key_ref {
                name = "minio-credentials"
                key  = "SECRET_KEY"
              }
            }
          }
          env {
            name  = "MC_HOST_backup"
            value = "http://$(MINIO_ACCESS_KEY):$(MINIO_SECRET_KEY)@minio.minio:9000"
          }
          env {
            name  = "MC_BUCKET"
            value = local.bucket_name
          }
        }
      }
    }
    backoff_limit = 0
  }
}
