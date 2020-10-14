
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


module "gke-setup-blue" {
  source   = "../../../terraform-modules/gke-setup"
  settings = var.settings
  cluster  = "sandbox"
  color    = "blue"
}

module "k8s-istio" {
  source                          = "../../../terraform-modules/k8s-istio"
  gke_cluster_connection_settings = module.gke-setup-blue.gke_cluster_connection_settings
  settings                        = var.settings
  cluster                         = "sandbox"
  color                           = "blue"
  depends_on                      = [module.gke-setup-blue]
}

module "k8s-misc-operators" {
  source                          = "../../../terraform-modules/k8s-misc"
  gke_cluster_connection_settings = module.gke-setup-blue.gke_cluster_connection_settings
  settings                        = var.settings
  cluster                         = "sandbox"
  color                           = "blue"
  depends_on                      = [module.k8s-istio]
}
# oidc_discovery_url              = var.oidc_discovery_url
# oidc_client_id                  = var.oidc_client_id
# oidc_client_secret              = var.oidc_client_secret
# node_pool                       = module.gke-setup-blue.node_pool
# providers = {
#   google     = google
#   kubernetes = kubernetes.kubernetes-blue
#   helm       = helm.helm-blue
# }
