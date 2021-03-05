module "mongod-backup" {
  source = "../../../terraform-modules/k8s-vault-mongo-backup"
  providers = {
    kubernetes = kubernetes.kubernetes-inactive
  }
}
