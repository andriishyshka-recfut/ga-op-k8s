
locals {
  json_exporter_version = lookup(var.Settings.clusters[var.Cluster].versions.json-exporter, "version", "v1.1.0")
  json_exporter_port = 8000
}

resource "kubernetes_deployment_v1" "json_exporter" {
  count = var.Cluster == "production" ? 1 : 0
  metadata {
    name      = "json-exporter"
    namespace = local.prometheusNs
    labels = {
      app     = "json-exporter"
      release = "prometheus"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "json-exporter"
      }
    }

    template {
      metadata {
        labels = {
          app     = "json-exporter"
          release = "prometheus"
        }
        annotations = {
          "sidecar.istio.io/inject" = "false"
          "co.elastic.logs/enabled" =  "true"
        }
      }

      spec {
        container {
          image = "${var.artifactoryRepoDomain}/ga-op-docker-local/json-exporter:${local.json_exporter_version}"
          name  = "json-exporter"
          args = ["/workspace/json-exporter-config.yaml"]
          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "150m"
              memory = "150Mi"
            }
          }
          port {
            container_port = local.json_exporter_port
            name           = "metrics"
          }
          liveness_probe {
            tcp_socket {
              port = local.json_exporter_port
            }

            initial_delay_seconds = 3
            period_seconds        = 10
            success_threshold     = 1
            failure_threshold     = 3
          }
          readiness_probe {
            tcp_socket {
              port = local.json_exporter_port
            }

            initial_delay_seconds = 3
            period_seconds        = 10
            success_threshold     = 1
            failure_threshold     = 3
          }
          volume_mount {
            mount_path = "/workspace"
            name       = kubernetes_secret.json_exporter_config[0].metadata[0].name
          }
        }
        image_pull_secrets {
          name = "harbor"
        }
        volume {
          name = kubernetes_secret.json_exporter_config[0].metadata[0].name
          secret {
            secret_name = kubernetes_secret.json_exporter_config[0].metadata[0].name
            items {
              key  = "json-exporter-config.yaml"
              path = "json-exporter-config.yaml"
            }
          }
        }
      }
    }
  }
}

data "vault_generic_secret" "captcha_creds" {
  count = var.Cluster == "production" ? 1 : 0
  path = "secret/core/captcha"
}

resource "kubernetes_secret" "json_exporter_config" {
  count = var.Cluster == "production" ? 1 : 0
  metadata {
    name      = "json-exporter-config"
    namespace = local.prometheusNs
  }

  data = {
    "json-exporter-config.yaml" = templatefile("${path.module}/json-exporter-config.tftpl", { TWOCAPTCHA_API_KEY = data.vault_generic_secret.captcha_creds[0].data.TWOCAPTCHA_API_KEY , ANTICAPTCHA_API_KEY = data.vault_generic_secret.captcha_creds[0].data.ANTICAPTCHA_API_KEY })
  }
}