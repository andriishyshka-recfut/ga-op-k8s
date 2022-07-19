
data "http" "grafana_dashboard_harbor" {
  url = "https://grafana.com/api/dashboards/14075/revisions/2/download"

  # Optional request headers
  request_headers = {
    Accept = "application/json"
  }
}

resource "kubernetes_config_map" "harbor_dashboards" {
  metadata {
    name = "harbor-dashboard"
    namespace = "monitoring"
    labels = {
      grafana_dashboard = 1
    }
  }

  data = {
    "harbor.json"             = replace(data.http.grafana_dashboard_harbor.body, "$${DS_HARBOR-PROMETHEUS}","Prometheus")
  }

}


resource "kubectl_manifest" "harbor" {
    yaml_body = file("${path.module}/harbor.yaml")
}
