
provider "google" {
  # version = "v3.19.0"
}

provider "google-beta" {
  # version = "v3.19.0"
}


locals {
  gkeClusterEndpoint   = module.gke-setup-green.GkeClusterConnectionSettings.HOST
  gkeBearerToken       = module.gke-setup-green.GkeClusterConnectionSettings.API_KEY
  clusterCaCertificate = module.gke-setup-green.GkeClusterConnectionSettings.CLUSTER_CA_CERTIFICATE
}

provider "helm" {
  kubernetes {
    load_config_file       = false
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
