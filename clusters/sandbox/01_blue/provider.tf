provider "google" {
  # version = "v3.19.0"
}

provider "google-beta" {
  # version = "v3.19.0"
}



locals {
  gkeClusterEndpoint   = module.gke-setup-blue.GkeClusterConnectionSettings.HOST
  gkeBearerToken       = module.gke-setup-blue.GkeClusterConnectionSettings.API_KEY
  clusterCaCertificate = module.gke-setup-blue.GkeClusterConnectionSettings.CLUSTER_CA_CERTIFICATE
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
    bucket = "terraform-state-222"
    prefix = "tf-blue-green/blue-state"
  }
}
