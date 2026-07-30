locals {
  etl_minio_exporter_version = lookup(var.Settings.clusters[var.Cluster].versions.etl-minio-exporter, "version", "3.12.5")
}

data "vault_generic_secret" "etl_minio_exporter_config" {
  path = "secret/mw/monitoring/prometheus/etl-minio-exporter-config"
}

resource "kubernetes_config_map" "etl_minio_exporter_config" {
  metadata {
    name      = "etl-minio-exporter-config"
    namespace = local.prometheusNs
  }

  data = {
    minio_endpoint              = data.vault_generic_secret.etl_minio_exporter_config.data.minio_endpoint,
    minio_etl_bucket_name       = data.vault_generic_secret.etl_minio_exporter_config.data.minio_etl_bucket_name,
    minio_kubescape_bucket_name = data.vault_generic_secret.etl_minio_exporter_config.data.minio_kubescape_bucket_name,
    minio_etl_hourly_delta      = data.vault_generic_secret.etl_minio_exporter_config.data.minio_etl_hourly_delta,
    minio_etl_bihourly_delta    = data.vault_generic_secret.etl_minio_exporter_config.data.minio_etl_bihourly_delta,
    minio_etl_daily_delta       = data.vault_generic_secret.etl_minio_exporter_config.data.minio_etl_daily_delta,
    minio_etl_weekly_delta      = data.vault_generic_secret.etl_minio_exporter_config.data.minio_etl_weekly_delta,
    minio_etl_exclude_list      = data.vault_generic_secret.etl_minio_exporter_config.data.minio_etl_exclude_list,
    metrics_server_port         = data.vault_generic_secret.etl_minio_exporter_config.data.metrics_server_port,
    minio_refresh_interval      = data.vault_generic_secret.etl_minio_exporter_config.data.minio_refresh_interval
  }
}

data "vault_generic_secret" "minio_creds" {
  path = "secret/minio/users"
}

resource "kubernetes_secret" "minio_creds" {
  metadata {
    name      = "etl-minio-exporter-creds"
    namespace = local.prometheusNs
  }
  data = {
    access_key = jsondecode(data.vault_generic_secret.minio_creds.data["etl_exporter"]).accessKey,
    secret_key = jsondecode(data.vault_generic_secret.minio_creds.data["etl_exporter"]).secretKey
  }
}

resource "kubernetes_service_account_v1" "etl_cronjob_reader" {
  metadata {
    name      = "etl-cronjob-reader"
    namespace = "monitoring"
  }
}

resource "kubernetes_role_v1" "etl_cronjob_reader" {
  metadata {
    name      = "cronjob-reader"
    namespace = "etl"
  }

  rule {
    api_groups = ["batch"]
    resources  = ["cronjobs"]
    verbs      = ["get"]
  }
}

resource "kubernetes_role_binding_v1" "etl_cronjob_reader" {
  metadata {
    name      = "monitoring-cronjob-reader"
    namespace = "etl"
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.etl_cronjob_reader.metadata[0].name
    namespace = kubernetes_service_account_v1.etl_cronjob_reader.metadata[0].namespace
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role_v1.etl_cronjob_reader.metadata[0].name
  }
}

resource "kubernetes_deployment_v1" "etl_minio_exporter" {
  metadata {
    name      = "etl-minio-exporter"
    namespace = local.prometheusNs
    labels = {
      app     = "etl-minio-exporter"
      release = "prometheus"
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
          app     = "etl-minio-exporter"
          release = "prometheus"
        }
        annotations = {
          "sidecar.istio.io/inject" = "false"
        }
      }

      spec {
        container {
          image             = "harbor.regemini.io/op/etl-minio-exporter:${local.etl_minio_exporter_version}"
          image_pull_policy = "Always"
          name              = "etl-minio-exporter"

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
                key  = "minio_endpoint"
                name = kubernetes_config_map.etl_minio_exporter_config.metadata.0.name
              }
            }
          }
          env {
            name = "MINIO_ACCESS_KEY"
            value_from {
              secret_key_ref {
                key  = "access_key"
                name = kubernetes_secret.minio_creds.metadata.0.name
              }
            }
          }
          env {
            name = "MINIO_SECRET_KEY"
            value_from {
              secret_key_ref {
                key  = "secret_key"
                name = kubernetes_secret.minio_creds.metadata.0.name
              }
            }
          }
          env {
            name = "MINIO_ETL_BUCKET_NAME"
            value_from {
              config_map_key_ref {
                key  = "minio_etl_bucket_name"
                name = kubernetes_config_map.etl_minio_exporter_config.metadata.0.name
              }
            }
          }
          env {
            name = "MINIO_KUBESCAPE_BUCKET_NAME"
            value_from {
              config_map_key_ref {
                key  = "minio_kubescape_bucket_name"
                name = kubernetes_config_map.etl_minio_exporter_config.metadata.0.name
              }
            }
          }
          env {
            name = "MINIO_ETL_HOURLY_DELTA"
            value_from {
              config_map_key_ref {
                key  = "minio_etl_hourly_delta"
                name = kubernetes_config_map.etl_minio_exporter_config.metadata.0.name
              }
            }
          }
          env {
            name = "MINIO_ETL_BIHOURLY_DELTA"
            value_from {
              config_map_key_ref {
                key  = "minio_etl_bihourly_delta"
                name = kubernetes_config_map.etl_minio_exporter_config.metadata.0.name
              }
            }
          }
          env {
            name = "MINIO_ETL_DAILY_DELTA"
            value_from {
              config_map_key_ref {
                key  = "minio_etl_daily_delta"
                name = kubernetes_config_map.etl_minio_exporter_config.metadata.0.name
              }
            }
          }
          env {
            name = "MINIO_ETL_WEEKLY_DELTA"
            value_from {
              config_map_key_ref {
                key  = "minio_etl_weekly_delta"
                name = kubernetes_config_map.etl_minio_exporter_config.metadata.0.name
              }
            }
          }
          env {
            name = "MINIO_ETL_EXCLUDE_LIST"
            value_from {
              config_map_key_ref {
                key  = "minio_etl_exclude_list"
                name = kubernetes_config_map.etl_minio_exporter_config.metadata.0.name
              }
            }
          }
          env {
            name = "MINIO_REFRESH_INTERVAL"
            value_from {
              config_map_key_ref {
                key  = "minio_refresh_interval"
                name = kubernetes_config_map.etl_minio_exporter_config.metadata.0.name
              }
            }
          }
          env {
            name = "METRICS_SERVER_PORT"
            value_from {
              config_map_key_ref {
                key  = "metrics_server_port"
                name = kubernetes_config_map.etl_minio_exporter_config.metadata.0.name
              }
            }
          }
          port {
            container_port = 8000
            name           = "metrics"
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
        service_account_name = kubernetes_service_account_v1.etl_cronjob_reader.metadata[0].name
        image_pull_secrets {
          name = "harbor"
        }
      }
    }
  }
}
