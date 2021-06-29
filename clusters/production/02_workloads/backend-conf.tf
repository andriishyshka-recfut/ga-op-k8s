
terraform {
  backend "gcs" {
    bucket = "terraform-state-production111"
    prefix = "terraform-production-workloads/state-8"
  }
  required_providers {
    kubectl = {
      source  = "registry.terraform.io/gavinbunney/kubectl"
      version = ">= 1.10.0"
    }
  }
}

provider "kubectl" {
  # alias = "kube"
  cluster_ca_certificate = data.vault_generic_secret.k8s_auth.data.CLUSTER_CA_CERTIFICATE
  host                   = data.vault_generic_secret.k8s_auth.data.HOST
  token                  = data.vault_generic_secret.k8s_auth.data.k8s_sa_token

}
