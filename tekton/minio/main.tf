

terraform {
  # The configuration for this backend will be filled in by Terragrunt
  backend "kubernetes" {
    secret_suffix    = "minio-state"
    namespace = "tekton-pipelines"
    load_config_file = false
  }
}

module "minio" {
  source   = "../../terraform-modules/k8s-vault-minio"
  Settings = var.Settings
  Cluster  = var.Cluster
  Color    = local.activeCluster
  depends_on = [
    kubernetes_namespace.ns
  ]
}
