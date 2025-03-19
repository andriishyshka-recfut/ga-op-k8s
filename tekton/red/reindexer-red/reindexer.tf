module "reindexer" {
  source            = "../../../terraform-modules/k8s-vault-reindexer"
  reindexer         = var.Settings.clusters[var.Cluster][var.Color].reindexer
  reindexer_version = var.Settings.clusters[var.Cluster].versions.reindexer.reindexer_version
  Settings          = var.Settings
  Cluster           = var.Cluster
  Color             = var.Color
}