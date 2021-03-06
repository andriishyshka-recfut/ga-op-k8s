

module "prometheus-kafka-exporter" {
  source   = "../../../terraform-modules/k8s-prometheus-kafka-exporter"
  Settings = var.Settings
  Cluster  = "production"
  Color    = local.activeCluster
}
