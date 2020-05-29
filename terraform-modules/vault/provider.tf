
provider "google" {
  version = "v3.19.0"
}

provider "helm" {
  kubernetes {
    load_config_file = false
    host  = var.gke_cluster_endpoint
    token = var.gke_bearer_token
    cluster_ca_certificate = var.cluster_ca_certificate
  }
}

provider "kubernetes" {
    load_config_file = false
    host  = var.gke_cluster_endpoint
    token = var.gke_bearer_token
    cluster_ca_certificate = var.cluster_ca_certificate

}
