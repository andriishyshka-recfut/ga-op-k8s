module "postgres" {
  source                       = "../../../terraform-modules/k8s-vault-postgres-post"
  Cluster                      = var.Cluster
  Color                        = var.Color
  Settings                     = var.Settings
  GkeClusterConnectionSettings = local.gkeClusterConnectionSettings
  VaultAddress                 = var.VaultAddress
}


