provider "google" {
  # version = "v3.19.0"
}

provider "google-beta" {
  # version = "v3.19.0"
}


provider "helm" {
  alias = "helm-blue"
  kubernetes {
    load_config_file       = false
    host                   = module.gke-setup-blue.gke_cluster_endpoint
    token                  = module.gke-setup-blue.gke_bearer_token
    cluster_ca_certificate = module.gke-setup-blue.cluster_ca_certificate
  }
}

provider "kubernetes" {
  alias                  = "kubernetes-blue"
  load_config_file       = false
  host                   = module.gke-setup-blue.gke_cluster_endpoint
  token                  = module.gke-setup-blue.gke_bearer_token
  cluster_ca_certificate = module.gke-setup-blue.cluster_ca_certificate

}
