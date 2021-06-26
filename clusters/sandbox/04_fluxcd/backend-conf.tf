


terraform {
  backend "gcs" {
    bucket = "terraform-state-222"
    prefix = "tf-fluxcd/state-3"
  }
  required_providers {
    kubernetes = {
      version = "2.0.1"
    }
    kubectl = {
      source  = "registry.terraform.io/gavinbunney/kubectl"
      version = ">= 1.10.0"
    }
    flux = {
      source  = "registry.terraform.io/fluxcd/flux"
      version = ">= 0.0.13"
    }
  }

}
output "ActiceCluuster" {
  value = local.activeCluster
}


provider "kubectl" {
  # alias = "kube"
  cluster_ca_certificate = data.vault_generic_secret.k8s_auth.data.CLUSTER_CA_CERTIFICATE
  host                   = data.vault_generic_secret.k8s_auth.data.HOST
  token                  = data.vault_generic_secret.k8s_auth.data.k8s_sa_token

}
provider "flux" {
  # alias = "fluxcd"
}
