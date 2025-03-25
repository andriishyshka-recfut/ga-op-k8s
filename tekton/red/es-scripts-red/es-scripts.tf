module "es-scripts" {
  source            = "../../../terraform-modules/k8s-vault-es-scripts"
  reindexer         = var.Settings.clusters[var.Cluster][var.Color].reindexer
  reindexer_version = var.Settings.clusters[var.Cluster].versions.reindexer.reindexer_version
  rebalancer         = var.Settings.clusters[var.Cluster][var.Color].rebalancer
  rebalancer_version = var.Settings.clusters[var.Cluster].versions.rebalancer.rebalancer_version
  Settings          = var.Settings
  Cluster           = var.Cluster
  Color             = var.Color
}