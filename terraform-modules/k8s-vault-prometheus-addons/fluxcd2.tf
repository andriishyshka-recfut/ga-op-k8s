# data "kubectl_file_documents" "fluxcd2_podmonitor" {
#   content = file("${path.module}/fluxcd-podmonitor.yaml")
# }

# resource "kubectl_manifest" "fluxcd2_podmonitor" {
#   yaml_body = file("${path.module}/fluxcd-podmonitor.yaml")
# }

# resource "kubernetes_manifest" "fluxcd2_podmonitor" {
#   count    = 1
#   manifest = yamldecode(element(data.kubectl_file_documents.fluxcd2_podmonitor.documents, count.index))
# }
data "http" "grafana_dashboard_fluxcd1" {
  url = "https://raw.githubusercontent.com/fluxcd/flux2/main/manifests/monitoring/monitoring-config/dashboards/cluster.json"

  # Optional request headers
  request_headers = {
    Accept = "application/json"
  }
}

data "http" "grafana_dashboard_fluxcd2" {
  url = "https://raw.githubusercontent.com/fluxcd/flux2/main/manifests/monitoring/monitoring-config/dashboards/control-plane.json"

  # Optional request headers
  request_headers = {
    Accept = "application/json"
  }
}

resource "kubernetes_config_map" "fluxcd2_dashboards" {
  metadata {
    name      = "fluxcd-dashboard"
    namespace = "monitoring"
    labels = {
      grafana_dashboard = 1
    }
  }

  data = {
    "cluster.json"       = replace(data.http.grafana_dashboard_fluxcd1.response_body, "$${DS_PROMETHEUS}", "Prometheus")
    "control-plane.json" = replace(data.http.grafana_dashboard_fluxcd2.response_body, "$${DS_PROMETHEUS}", "Prometheus")
  }

}
