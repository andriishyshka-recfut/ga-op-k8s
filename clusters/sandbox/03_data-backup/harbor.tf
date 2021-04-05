module "harbor-backup" {
  source = "../../../terraform-modules/k8s-vault-harbor-backup"
  providers = {
    kubernetes = kubernetes.kubernetes-inactive
  }
}
