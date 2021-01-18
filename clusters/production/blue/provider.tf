
terraform {
  backend "gcs" {
    bucket = "terraform-state-production111"
    prefix = "terraform-prod-blue/state"
  }
}



provider "google" {
  # version = "v3.19.0"
}

provider "google-beta" {
  # version = "v3.19.0"
}



locals {
  gkeClusterEndpoint   = module.gke-setup.GkeClusterConnectionSettings.HOST
  gkeBearerToken       = module.gke-setup.GkeClusterConnectionSettings.API_KEY
  clusterCaCertificate = module.gke-setup.GkeClusterConnectionSettings.CLUSTER_CA_CERTIFICATE
}

provider "helm" {
  kubernetes {
    host                   = local.gkeClusterEndpoint
    token                  = local.gkeBearerToken
    cluster_ca_certificate = local.clusterCaCertificate
  }
}

provider "kubernetes" {
  load_config_file       = false
  host                   = local.gkeClusterEndpoint
  token                  = local.gkeBearerToken
  cluster_ca_certificate = local.clusterCaCertificate

}
