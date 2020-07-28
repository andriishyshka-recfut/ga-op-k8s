
provider "google" {
  # version = "v3.19.0"
}

provider "google-beta" {
  # version = "v3.19.0"
}

provider "helm" {
  alias = "helm-green"
  kubernetes {
    load_config_file       = false
    host                   = module.gke-setup-green.gke_cluster_endpoint
    token                  = module.gke-setup-green.gke_bearer_token
    cluster_ca_certificate = module.gke-setup-green.cluster_ca_certificate
  }
}

provider "kubernetes" {
  alias                  = "kubernetes-green"
  load_config_file       = false
  host                   = module.gke-setup-green.gke_cluster_endpoint
  token                  = module.gke-setup-green.gke_bearer_token
  cluster_ca_certificate = module.gke-setup-green.cluster_ca_certificate

}
