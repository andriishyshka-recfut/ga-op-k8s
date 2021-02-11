

module "harbor" {
  source              = "../../../terraform-modules/k8s-vault-harbor"
  DoRestoreFromBackup = true
  depends_on          = [module.namespaces]
}
