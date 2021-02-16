
module "mongo" {
  source              = "../../../terraform-modules/k8s-vault-mongo"
  CredsPath           = "secret/mongo/magescanner"
  DoRestoreFromBackup = true
  depends_on          = [module.namespaces, module.minio]
}
