resource "kubernetes_namespace" "ns" {
    metadata {
    name = "minio2"
    labels = {
      istio-injection = "enabled"
    }
  }
}


terraform {
  # The configuration for this backend will be filled in by Terragrunt
  backend "kubernetes" {
    secret_suffix    = "minio-state"
    namespace = "kube-system"
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
