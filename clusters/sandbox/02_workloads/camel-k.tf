
module "camel-k" {
  source = "../../../terraform-modules/k8s-vault-camel-k"
  depends_on = [module.namespaces]
}
