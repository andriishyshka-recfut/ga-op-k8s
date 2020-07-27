provider "google" {
  # version = "v3.19.0"
}

provider "google-beta" {
  # version = "v3.19.0"
}


provider "helm" {
  alias = "helm"
  kubernetes {
    load_config_file       = false
    host                   = module.gke-setup.gke_cluster_endpoint
    token                  = module.gke-setup.gke_bearer_token
    cluster_ca_certificate = module.gke-setup.cluster_ca_certificate
  }
}

provider "kubernetes" {
  alias                  = "kubernetes"
  load_config_file       = false
  host                   = module.gke-setup.gke_cluster_endpoint
  token                  = module.gke-setup.gke_bearer_token
  cluster_ca_certificate = module.gke-setup.cluster_ca_certificate

}
