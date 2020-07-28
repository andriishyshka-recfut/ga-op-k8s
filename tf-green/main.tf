terraform {
  backend "gcs" {
    bucket = "terraform-state-222"
    prefix = "tf-green/state"
  }
}

// should be set with tfvars
variable "settings" {}
variable "oidc_discovery_url" { default = "SAMPLE" }
variable "oidc_client_id" { default = "SAMPLE" }
variable "oidc_client_secret" { default = "SAMPLE" }

output "is-active" {
  value = lookup(var.settings["green"], "active", false) ? 1 : 0
}


module "gke-setup-green" {
  source   = "../terraform-modules/gke-setup"
  settings = var.settings
  cluster  = "green"

  providers = {
    google      = google
    google-beta = google-beta
  }
}


module "post-install-green" {
  source                 = "../terraform-modules/k8s-post-install"
  gke_cluster_endpoint   = module.gke-setup-green.gke_cluster_endpoint
  gke_bearer_token       = module.gke-setup-green.gke_bearer_token
  cluster_ca_certificate = module.gke-setup-green.cluster_ca_certificate
  settings               = var.settings
  cluster                = "green"
  oidc_discovery_url     = var.oidc_discovery_url
  oidc_client_id         = var.oidc_client_id
  oidc_client_secret     = var.oidc_client_secret
  vault_resources        = module.gke-setup-green.vault_resources
  node_pool              = module.gke-setup-green.node_pool

  providers = {
    google     = google
    kubernetes = kubernetes.kubernetes-green
    helm       = helm.helm-green

  }
}
