
module "kafka" {
  source = "../../../terraform-modules/k8s-vault-kafka"
  depends_on = [module.namespaces]
}
