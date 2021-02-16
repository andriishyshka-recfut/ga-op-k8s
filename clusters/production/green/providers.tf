
provider "google" {
}

provider "google-beta" {
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
terraform {
  backend "gcs" {
    bucket = "terraform-state-production111"
    prefix = "terraform-prod-green/state"
  }
  required_providers {
    kubernetes = {
      version = "2.0.1"
    }
  }
}
