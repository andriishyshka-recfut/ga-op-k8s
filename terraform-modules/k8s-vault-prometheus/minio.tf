

data "kubectl_file_documents" "minio" {
  content = file("${path.module}/minio.yaml")
}

resource "kubectl_manifest" "minio" {
  count     = 2
  yaml_body = element(data.kubectl_file_documents.minio.documents, count.index)
}



data "http" "grafana_dashboard_minio" {
  url = "https://raw.githubusercontent.com/minio/minio/master/docs/metrics/prometheus/grafana/minio-overview.json"

  # Optional request headers
  request_headers = {
    Accept = "application/json"
  }
}

resource "kubernetes_config_map" "minio_dashboards" {
  metadata {
    name      = "minio-dashboard"
    namespace = "monitoring"
    labels = {
      grafana_dashboard = 1
    }
  }

  data = {
    "minio.json" = replace(data.http.grafana_dashboard_minio.body, "$${DS_PROMETHEUS}", "Prometheus")
  }

}
