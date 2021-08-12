
data "kubectl_file_documents" "go" {
    content = file("${path.module}/go-podmonitor.yaml")
}

resource "kubectl_manifest" "go" {
    count     = 1
    yaml_body = element(data.kubectl_file_documents.go.documents, count.index)
}

data "http" "grafana_dashboard_go" {
  url = "https://grafana.com/api/dashboards/6671/revisions/2/download"

  # Optional request headers
  request_headers = {
    Accept = "application/json"
  }
}

resource "kubernetes_config_map" "go_dashboards" {
  metadata {
    name = "go-dashboard"
    namespace = "monitoring"
    labels = {
      grafana_dashboard = 1
    }
  }

  data = {
    "go.json"             = replace(data.http.grafana_dashboard_go.body, "$${DS_PROMETHEUS-APL}","Prometheus")
  }

}
