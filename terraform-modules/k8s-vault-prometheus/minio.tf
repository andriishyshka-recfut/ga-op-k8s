
resource "kubectl_manifest" "minio_podmonitor" {
    yaml_body  = file("${path.module}/minio-podmonitor.yaml")
    depends_on = [
        helm_release.prometheus
    ]
}
resource "kubectl_manifest" "minio_servicemonitor" {
    yaml_body  = file("${path.module}/minio-servicemonitor.yaml")
    depends_on = [
        helm_release.prometheus
    ]
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
    name = "minio-dashboard"
    namespace = "monitoring"
    labels = {
      grafana_dashboard = 1
    }
  }

  data = {
    "minio.json"             = replace(data.http.grafana_dashboard_minio.body, "$${DS_PROMETHEUS}","Prometheus")
  }

}
