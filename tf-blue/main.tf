
terraform {
  backend "gcs" {
    bucket = "terraform-state-222"
    prefix = "tf-blue-green/state"
  }
}

// should be set with tfvars
variable "settings" {}
variable "oidc_discovery_url" { default = "SAMPLE" }
variable "oidc_client_id" { default = "SAMPLE" }
variable "oidc_client_secret" { default = "SAMPLE" }

module "vault-persistent-blue" {
  source   = "../terraform-modules/vault-persistent-resources"
  settings = var.settings
  cluster  = "blue"

  providers = {
    google = google
  }
}

module "dns" {
  source   = "../terraform-modules/dns"
  settings = var.settings
  cluster  = "blue"

  providers = {
    google = google
  }
}
# module "gke-setup-blue" {
#   source   = "../terraform-modules/gke-setup"
#   settings = var.settings
#   cluster  = "blue"
#
#   providers = {
#     google      = google
#     google-beta = google-beta
#   }
# }
#
#
# module "post-install-blue" {
#   source                 = "../terraform-modules/k8s-post-install"
#   gke_cluster_endpoint   = module.gke-setup-blue.gke_cluster_endpoint
#   gke_bearer_token       = module.gke-setup-blue.gke_bearer_token
#   cluster_ca_certificate = module.gke-setup-blue.cluster_ca_certificate
#   settings               = var.settings
#   cluster                = "blue"
#   oidc_discovery_url     = var.oidc_discovery_url
#   oidc_client_id         = var.oidc_client_id
#   oidc_client_secret     = var.oidc_client_secret
#   vault_resources        = module.vault-persistent-blue.vault_resources
#   node_pool              = module.gke-setup-blue.node_pool
#
#   providers = {
#     google     = google
#     kubernetes = kubernetes.kubernetes-blue
#     helm       = helm.helm-blue
#
#   }
# }
