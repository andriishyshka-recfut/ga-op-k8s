resource "kubernetes_config_map" "dome_dashboards" {
  metadata {
    name      = "dome-dashboard"
    namespace = "monitoring"
    labels = {
      grafana_dashboard = 1
    }
  }

  data = {
    "urlscan-preps.json" = file("${path.module}/dashboards/dome-preps.json")
  }

}
