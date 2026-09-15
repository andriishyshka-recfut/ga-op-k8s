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
    "k8s-addons-prometheus.json" = file("${path.module}/dashboards/k8s-addons-prometheus.json")
    "k8s-psmdb-mongo-overview.json" = file("${path.module}/dashboards/k8s-psmdb-mongo-overview.json")
    "k8s-psmdb-mongo-full.json" = file("${path.module}/dashboards/k8s-psmdb-mongo-full.json")
    "k8s-addons-trivy-operator.json" = file("${path.module}/dashboards/k8s-addons-trivy-operator.json")
    "k8s-system-api-server.json" = file("${path.module}/dashboards/k8s-system-api-server.json")
    "k8s-system-coredns.json" = file("${path.module}/dashboards/k8s-system-coredns.json")
    "k8s-views-global.json" = file("${path.module}/dashboards/k8s-views-global.json")
    "k8s-views-namespaces.json" = file("${path.module}/dashboards/k8s-views-namespaces.json")
    "k8s-views-nodes.json" = file("${path.module}/dashboards/k8s-views-nodes.json")
    "k8s-views-pods.json" = file("${path.module}/dashboards/k8s-views-pods.json")
    "k8s-volumes-cluster.json" = file("${path.module}/dashboards/k8s-volumes-cluster.json")
    "k8s-volumes-namespace.json" = file("${path.module}/dashboards/k8s-volumes-namespace.json")
    "thanos-alerts-by-severity.json" = file("${path.module}/dashboards/thanos-alerts-by-severity.json")
    "etl-alerts-dashboard.json" = file("${path.module}/dashboards/etl-alerts-dashboard.json")
  }
}
