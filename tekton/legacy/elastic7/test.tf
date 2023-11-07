module "elastic-helm" {
  source = "../../../terraform-modules/k8s-vault-elastic-helm"

}

output "test" {
  value = module.elastic-helm.test
}
