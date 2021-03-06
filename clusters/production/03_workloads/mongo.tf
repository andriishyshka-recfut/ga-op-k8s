
module "mongo" {
  source              = "../../../terraform-modules/k8s-vault-mongo"
  CredsPath           = "secret/mongo/production"
  DoRestoreFromBackup = true
  depends_on          = [module.namespaces, module.minio]
}
