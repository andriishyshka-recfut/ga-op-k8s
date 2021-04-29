
resource "kubectl_manifest" "fluxcd2_podmonitor" {
    yaml_body  = file("${path.module}/fluxcd-podmonitor.yaml")
}

data "http" "grafana_dashboard_fluxcd1" {
  url = "https://raw.githubusercontent.com/fluxcd/flux2/main/manifests/monitoring/grafana/dashboards/cluster.json"

  # Optional request headers
  request_headers = {
    Accept = "application/json"
  }
}

data "http" "grafana_dashboard_fluxcd2" {
  url = "https://raw.githubusercontent.com/fluxcd/flux2/main/manifests/monitoring/grafana/dashboards/control-plane.json"

  # Optional request headers
  request_headers = {
    Accept = "application/json"
  }
}

resource "kubernetes_config_map" "fluxcd2_dashboards" {
  metadata {
    name = "kafka-exporter-dashboard"
    namespace = "monitoring"
    labels = {
      grafana_dashboard = 1
    }
  }

  data = {
    "cluster.json"             = replace(data.http.grafana_dashboard_fluxcd1.body, "$${DS_PROMETHEUS}","Prometheus")
    "control-plane.json"             = replace(data.http.grafana_dashboard_fluxcd2.body, "$${DS_PROMETHEUS}","Prometheus")
  }

}
