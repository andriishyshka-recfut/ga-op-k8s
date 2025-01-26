module "postgres" {
  source                       = "../../../terraform-modules/k8s-vault-postgres"
  Cluster                      = var.Cluster
  Color                        = var.Color
  VaultAddress                 = var.VaultAddress
  GkeClusterConnectionSettings = local.gkeClusterConnectionSettings
}
