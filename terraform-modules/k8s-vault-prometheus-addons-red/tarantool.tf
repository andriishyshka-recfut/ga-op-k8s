data "http" "grafana_dashboard_tarantool" {
  url = "https://grafana.com/api/dashboards/13054/revisions/18/download"

  # Optional request headers
  request_headers = {
    Accept = "application/json"
  }
}

resource "kubernetes_config_map" "tarantool_dashboard" {
  metadata {
    name      = "tarantool-dashboard"
    namespace = "monitoring"
    labels = {
      grafana_dashboard = 1
    }
  }

  data = {
    "tarantool.json" = data.http.grafana_dashboard_tarantool.response_body
  }

}
