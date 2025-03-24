data "kubectl_file_documents" "istio" {
  content = file("${path.module}/istio.yaml")
}

resource "kubectl_manifest" "istio" {
  count     = length(data.kubectl_file_documents.istio.documents)
  yaml_body = element(data.kubectl_file_documents.istio.documents, count.index)
}



data "http" "grafana_dashboard_istio1" {
  url = "https://grafana.com/api/dashboards/7639/revisions/71/download"

  # Optional request headers
  request_headers = {
    Accept = "application/json"
  }
}

resource "kubernetes_config_map" "istio_dashboards" {
  metadata {
    name      = "istio-dashboard"
    namespace = "monitoring"
    labels = {
      grafana_dashboard = 1
    }
  }

  data = {
    "istio1.json" = replace(data.http.grafana_dashboard_istio1.response_body, "$${DS_PROMETHEUS}", "Prometheus")

  }

}
