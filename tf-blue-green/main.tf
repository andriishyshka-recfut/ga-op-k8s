
terraform {
  backend "gcs" {
    bucket = "terraform-state-222"
    prefix = "tf-blue-green/state"
  }
}

// should be set with tfvars
variable "settings" {}

module "gke-setup" {
  source   = "../terraform-modules/gke-setup"
  settings = var.settings
  cluster  = "blue"

  providers = {
    google      = google
    google-beta = google-beta
  }
}



variable "oidc_discovery_url" { default = "SAMPLE" }
variable "oidc_client_id" { default = "SAMPLE" }
variable "oidc_client_secret" { default = "SAMPLE" }

module "post-install" {
  source                 = "../terraform-modules/k8s-post-install"
  gke_cluster_endpoint   = module.gke-setup.gke_cluster_endpoint
  gke_bearer_token       = module.gke-setup.gke_bearer_token
  cluster_ca_certificate = module.gke-setup.cluster_ca_certificate
  settings               = var.settings
  cluster                = "blue"
  oidc_discovery_url     = var.oidc_discovery_url
  oidc_client_id         = var.oidc_client_id
  oidc_client_secret     = var.oidc_client_secret
  vault_resources        = module.gke-setup.vault_resources
  node_pool              = module.gke-setup.node_pool

  providers = {
    google     = google
    kubernetes = kubernetes.kubernetes
    helm       = helm.helm

  }
}
