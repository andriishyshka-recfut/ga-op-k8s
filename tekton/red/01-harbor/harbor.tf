module "harbor" {
  source                       = "../../../terraform-modules/k8s-vault-harbor"
  DoRestoreFromBackup          = false
  GkeClusterConnectionSettings = local.gkeClusterConnectionSettings
  # depends_on                   = [module.harbor-backup]
  Cluster = var.Cluster
  Color   = var.Color
  Settings = var.Settings
}

# module "harbor-backup" {
#   source = "../../../terraform-modules/k8s-vault-harbor-backup"
# }