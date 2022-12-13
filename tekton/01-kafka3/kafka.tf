
module "kafka" {
  source                       = "../../terraform-modules/k8s-vault-kafka3"
  GkeClusterConnectionSettings = local.gkeClusterConnectionSettings
  Cluster                      = var.Cluster
  Settings                     = var.Settings
}
