provider "google" {
  version = "v3.19.0"
}

provider "google-beta" {
  version = "v3.19.0"
}


provider "helm" {
  kubernetes {
    load_config_file = false
    host  = "https://${google_container_cluster.cluster.endpoint}"
    token = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(google_container_cluster.cluster.master_auth[0].cluster_ca_certificate,)
  }
}

provider "kubernetes" {
  load_config_file = false
  host  = "https://${google_container_cluster.cluster.endpoint}"
  token = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.cluster.master_auth[0].cluster_ca_certificate,)
}
