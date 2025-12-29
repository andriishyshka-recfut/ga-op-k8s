locals {
  tektonResources = ["etl.yaml"]
}

module "k8s-vault-tekton-resources" {
  source    = "../../../terraform-modules/k8s-vault-tekton-resources"
  Settings  = var.Settings
  Resources = local.tektonResources
}