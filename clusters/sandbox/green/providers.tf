
provider "google" {
  # version = "v3.19.0"
}

provider "google-beta" {
  # version = "v3.19.0"
}


locals {
  gke_cluster_endpoint   = module.gke-setup-green.gke_cluster_connection_settings.HOST
  gke_bearer_token       = module.gke-setup-green.gke_cluster_connection_settings.API_KEY
  cluster_ca_certificate = module.gke-setup-green.gke_cluster_connection_settings.CLUSTER_CA_CERTIFICATE
}

provider "helm" {
  kubernetes {
    load_config_file       = false
    host                   = local.gke_cluster_endpoint
    token                  = local.gke_bearer_token
    cluster_ca_certificate = local.cluster_ca_certificate
  }
}

provider "kubernetes" {
  load_config_file       = false
  host                   = local.gke_cluster_endpoint
  token                  = local.gke_bearer_token
  cluster_ca_certificate = local.cluster_ca_certificate

}
