resource "kubernetes_deployment" "etl_observer" {
  metadata {
    name      = "etl-observer"
    namespace = "etl"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "etl-observer"
      }
    }
    template {
      metadata {
        labels = {
          app = "etl-observer"
        }
        annotations = {
          "co.elastic.logs/enabled" = "false"
        }
      }

      spec {
        container {
          name  = "flask"
          image = "harbor.regemini.io/op/etl-observer:v0.1.2"

          port {
            container_port = 5000
            name           = "endpoint"
            protocol       = "TCP"
          }

          env {
            name = "MINIO_ENDPOINT"
            value_from {
              secret_key_ref {
                name = "minio-default-settings"
                key  = "endpoint"
              }
            }
          }

          env {
            name = "BUCKET_NAME"
            value_from {
              secret_key_ref {
                name = "minio-default-settings"
                key  = "minio-bucket"
              }
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
        }
        image_pull_secrets {
          name = "harbor"
        }
      }
    }
  }
}






resource "kubernetes_service" "etl_observer" {
  metadata {
    name      = "etl-observer"
    namespace = "etl"

    labels = {
      app = "etl-observer"
    }
  }

  spec {
    selector = {
      app = "etl-observer"
    }

    port {
      protocol    = "TCP"
      port        = 5000
      target_port = 5000
    }

    type = "ClusterIP"
  }
}
