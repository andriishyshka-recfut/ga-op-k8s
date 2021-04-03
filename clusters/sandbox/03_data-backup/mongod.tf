module "mongod-backup" {
  source = "../../../terraform-modules/k8s-vault-mongo-backup"
  providers = {
    kubernetes = kubernetes.kubernetes-inactive
  }
}
module "mongod-restore" {
  source = "../../../terraform-modules/k8s-vault-mongo-restore"
  depends_on = [module.mongod-backup ]
}
