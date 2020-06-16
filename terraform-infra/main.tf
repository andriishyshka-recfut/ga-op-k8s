
terraform {
  backend "gcs" {
    bucket  = "terraform-state-222"
    prefix  = "terraform-infra/state"
  }
}



module "common-vars" {
  source = "../terraform-modules/common-vars"
}

module "gke-setup" {
  source = "../terraform-modules/gke-setup"

  settings = module.common-vars
  cluster = "infra"
}

provider "google" {
  alias = "google"
  version = "v3.19.0"
}

provider "helm" {
  alias = "helm"
  kubernetes {
    load_config_file = false
    host  = module.gke-setup.gke_cluster_endpoint
    token = module.gke-setup.gke_bearer_token
    cluster_ca_certificate = module.gke-setup.cluster_ca_certificate
  }
}

provider "kubernetes" {
    alias = "kubernetes"
    load_config_file = false
    host  = module.gke-setup.gke_cluster_endpoint
    token = module.gke-setup.gke_bearer_token
    cluster_ca_certificate = module.gke-setup.cluster_ca_certificate

}

variable "oidc_discovery_url" { default = "SAMPLE"}
variable  "oidc_client_id" { default = "SAMPLE"}
variable  "oidc_client_secret" { default = "SAMPLE"}

  module "vault" {
   source = "../terraform-modules/vault"
    gke_cluster_endpoint = module.gke-setup.gke_cluster_endpoint
    gke_bearer_token = module.gke-setup.gke_bearer_token
    cluster_ca_certificate = module.gke-setup.cluster_ca_certificate
    settings = module.common-vars
    cluster = "infra"
    vault-version = "1.4.2"
    oidc_discovery_url = var.oidc_discovery_url
    oidc_client_id = var.oidc_client_id
    oidc_client_secret = var.oidc_client_secret
    providers = {
      google = google.google
      kubernetes = kubernetes.kubernetes
      helm = helm.helm

    }

   }
