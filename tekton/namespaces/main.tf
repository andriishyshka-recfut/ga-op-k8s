

module "namespaces" {
  source   = "../../terraform-modules/k8s-vault-namespaces"
  Settings = var.Settings
  Cluster  = var.Cluster
  Color    = local.activeCluster

}

terraform {
  # The configuration for this backend will be filled in by Terragrunt
  backend "kubernetes" {
    secret_suffix    = "namespaces-state"
    namespace = "tekton-pipelines"
    load_config_file = false
  }
}
