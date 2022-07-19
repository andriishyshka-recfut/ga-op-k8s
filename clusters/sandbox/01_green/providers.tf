
provider "google" {
  # version = "v3.19.0"
}

provider "google-beta" {
  # version = "v3.19.0"
}

provider "vault" {
  address = "https://vault.t.regemini.io"
}

locals {
  gkeClusterEndpoint   = module.gke-setup-green.GkeClusterConnectionSettings.HOST
  gkeBearerToken       = module.gke-setup-green.GkeClusterConnectionSettings.API_KEY
  clusterCaCertificate = module.gke-setup-green.GkeClusterConnectionSettings.CLUSTER_CA_CERTIFICATE
}

provider "helm" {
  kubernetes {
    host                   = local.gkeClusterEndpoint
    token                  = local.gkeBearerToken
    cluster_ca_certificate = local.clusterCaCertificate
  }
}

provider "kubernetes" {
  host                   = local.gkeClusterEndpoint
  token                  = local.gkeBearerToken
  cluster_ca_certificate = local.clusterCaCertificate

}

provider "kubectl" {
  # alias = "kube"
  cluster_ca_certificate = module.gke-setup-green.GkeClusterConnectionSettings.CLUSTER_CA_CERTIFICATE
  host                   = module.gke-setup-green.GkeClusterConnectionSettings.HOST
  token                  = module.gke-setup-green.GkeClusterConnectionSettings.API_KEY
  load_config_file       = false
}
terraform {
  backend "gcs" {
    bucket = "terraform-state-222"
    prefix = "tf-blue-green/green-state"
  }
  required_providers {
    kubectl = {
      source = "gavinbunney/kubectl"
    }
    kubernetes = {
      version = "2.0.1"
    }
  }
}
