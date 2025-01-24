module "postgres" {
  source                       = "../../../terraform-modules/k8s-vault-postgres"
  Cluster                      = var.Cluster
  Color                        = var.Color
  Settings                     = var.Settings
  GkeClusterConnectionSettings = local.gkeClusterConnectionSettings
  VaultAddress                 = var.VaultAddress
}


output "test" {
  sensitive = true
  value     = module.postgres.test
}
