data "vault_generic_secret" "etl_minio_exporter_config" {
  path = "secret/op/monitoring/etl-minio-exporter-config"
}

resource "kubernetes_config_map" "etl_minio_exporter_config" {
  metadata {
    name = "etl-minio-exporter-creds"
    namespace = local.prometheusNs
  }

  data = {
    minio_endpoint         = data.vault_generic_secret.etl_minio_exporter_config.data.minio_endpoint,
    minio_bucket_name      = data.vault_generic_secret.etl_minio_exporter_config.data.minio_bucket_name,
    metrics_server_port    = data.vault_generic_secret.etl_minio_exporter_config.data.metrics_server_port,
    minio_refresh_interval = data.vault_generic_secret.etl_minio_exporter_config.data.minio_refresh_interval
  }
}

data "vault_generic_secret" "minio_creds" {
  path = "secret/minio/users"
}

resource "kubernetes_secret" "minio_creds" {
  metadata {
    name = "etl-minio-exporter-creds"
    namespace = local.prometheusNs
  }
  data = {
    access_key = jsondecode(data.vault_generic_secret.minio_creds.data["logstash-red"]).accessKey,
    secret_key = jsondecode(data.vault_generic_secret.minio_creds.data["logstash-red"]).secretKey
  }
}

resource "kubernetes_deployment_v1" "etl_minio_exporter" {
  metadata {
    name = "etl-minio-exporter"
    namespace = local.prometheusNs
    labels = {
      app = "etl-minio-exporter"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "etl-minio-exporter"
      }
    }

    template {
      metadata {
        labels = {
          app = "etl-minio-exporter"
        }
        annotations = {
          "sidecar.istio.io/inject" = "false"
        }
      }

      spec {
        container {
          image = "harbor.regemini.io/op/etl-minio-exporter:3"
          name  = "etl-minio-exporter"

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
          env {
            name = "MINIO_ENDPOINT"
            value_from {
                config_map_key_ref {
                    key = "minio_endpoint"
                    name = kubernetes_config_map.etl_minio_exporter_config.metadata.0.name
                }
            }
          }
          env {
            name = "MINIO_BUCKET_NAME"
            value_from {
                config_map_key_ref {
                    key = "minio_bucket_name"
                    name = kubernetes_config_map.etl_minio_exporter_config.metadata.0.name
                }
            }
          }
          env {
            name = "MINIO_REFRESH_INTERVAL"
            value_from {
                config_map_key_ref {
                    key = "minio_refresh_interval"
                    name = kubernetes_config_map.etl_minio_exporter_config.metadata.0.name
                }
            }
          }
          env {
            name = "METRICS_SERVER_PORT"
            value_from {
                config_map_key_ref {
                    key = "metrics_server_port"
                    name = kubernetes_config_map.etl_minio_exporter_config.metadata.0.name
                }
            }
          }
          env {
            name = "MINIO_ACCESS_KEY"
            value_from {
                secret_key_ref {
                    key = "access_key"
                    name = kubernetes_secret.minio_creds.metadata.0.name
                }
            }
          }
          env {
            name = "MINIO_SECRET_KEY"
            value_from {
                secret_key_ref {
                    key = "secret_key"
                    name = kubernetes_secret.minio_creds.metadata.0.name
                }
            }
          }
          port {
            container_port = 8000
            name = "metrics"
          }
          liveness_probe {
            tcp_socket {
              port = data.vault_generic_secret.etl_minio_exporter_config.data.metrics_server_port
            }

            initial_delay_seconds = 3
            period_seconds        = 10
            success_threshold     = 1
            failure_threshold     = 3
          }
          readiness_probe {
            tcp_socket {
              port = data.vault_generic_secret.etl_minio_exporter_config.data.metrics_server_port
            }

            initial_delay_seconds = 3
            period_seconds        = 10
            success_threshold     = 1
            failure_threshold     = 3
          }
        }
        image_pull_secrets {
          name = "harbor"
        }
      }
    }
  }
}

data "kubectl_file_documents" "etl_minio_exporter_servicemonitor" {
  content = file("${path.module}/etl-minio-exporter-servicemonitor.yaml")
}

resource "kubectl_manifest" "etl_minio_exporter_servicemonitor" {
  count     = 2
  yaml_body = element(data.kubectl_file_documents.etl_minio_exporter_servicemonitor.documents, count.index)
}

data "kubectl_file_documents" "etl_minio_exporter_rules" {
  content = templatefile("${path.module}/etl-minio-exporter-prometheusrule.yaml", { cluster_label : var.Cluster })
}

resource "kubectl_manifest" "etl_minio_exporter_rules" {
  count     = 1
  yaml_body = element(data.kubectl_file_documents.etl_minio_exporter_rules.documents, count.index)
}