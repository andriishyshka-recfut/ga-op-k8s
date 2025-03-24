data "http" "grafana_dashboard_kubescape" {
  url = "https://raw.githubusercontent.com/dwertent/kubescape/master/httphandler/examples/prometheus/grafana-kubescape-dashboard.json"

  # Optional request headers
  request_headers = {
    Accept = "application/json"
  }
}

resource "kubernetes_config_map" "kubescape_dashboard" {
  metadata {
    name      = "kubescape-dashboard"
    namespace = "monitoring"
    labels = {
      grafana_dashboard = 1
    }
  }

  data = {
    "kubescape.json" = data.http.grafana_dashboard_kubescape.response_body
  }

}
