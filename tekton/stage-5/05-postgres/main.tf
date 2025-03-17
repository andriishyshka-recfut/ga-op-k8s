module "postgres" {
  source                       = "../../../terraform-modules/k8s-vault-postgres"
  Cluster                      = var.Cluster
  Color                        = var.Color
  Settings                     = var.Settings
  VaultAddress                 = var.VaultAddress
  GkeClusterConnectionSettings = local.gkeClusterConnectionSettings
}
