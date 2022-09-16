module "harbor-backup" {
  source = "../../terraform-modules/k8s-vault-harbor-backup"
  providers = {
    kubernetes = kubernetes.kubernetes-inactive
  }
}

module "harbor" {
  source                       = "../../terraform-modules/k8s-vault-harbor"
  DoRestoreFromBackup          = true
  GkeClusterConnectionSettings = local.gkeClusterConnectionSettings
  depends_on                   = [module.harbor-backup]
}
