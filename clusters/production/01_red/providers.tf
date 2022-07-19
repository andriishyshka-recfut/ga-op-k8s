
provider "google" {
}

provider "google-beta" {
}


locals {
  gkeClusterEndpoint   = module.gke-setup-red.GkeClusterConnectionSettings.HOST
  gkeBearerToken       = module.gke-setup-red.GkeClusterConnectionSettings.API_KEY
  clusterCaCertificate = module.gke-setup-red.GkeClusterConnectionSettings.CLUSTER_CA_CERTIFICATE
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

provider "vault" {
  address = "https://vault.p.regemini.io"
}
terraform {
  backend "gcs" {
    bucket = "terraform-state-production111"
    prefix = "terraform-prod-red/state"
  }
}
