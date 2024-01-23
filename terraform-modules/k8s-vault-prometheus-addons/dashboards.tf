resource "kubernetes_config_map" "custom_dashboards" {
  metadata {
    name      = "custom-dashboards"
    namespace = "monitoring"
    labels = {
      grafana_dashboard = 1
    }
  }

  data = {
    "dome-preps.json"    = file("${path.module}/dashboards/dome-preps.json")
    "urlscan-preps.json" = file("${path.module}/dashboards/urlscan-preps.json")
    "kubescape-scans.json" = file("${path.module}/dashboards/kubescape-scans.json")
  }

}
