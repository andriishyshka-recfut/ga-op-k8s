module "harbor" {
  source                       = "../../../terraform-modules/k8s-vault-harbor"
  DoRestoreFromBackup          = false
  GkeClusterConnectionSettings = local.gkeClusterConnectionSettings
}

module "harbor-backup" {
  source = "../../../terraform-modules/k8s-vault-harbor-backup"
  depends_on                   = [module.harbor]
}