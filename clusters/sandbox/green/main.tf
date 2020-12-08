
terraform {
  backend "gcs" {
    bucket = "terraform-state-222"
    prefix = "tf-blue-green/green-state"
  }
}

// should be set with tfvars
variable "settings" {}
variable "oidc_discovery_url" { default = "SAMPLE" }
variable "oidc_client_id" { default = "SAMPLE" }
variable "oidc_client_secret" { default = "SAMPLE" }


module "gke-setup-green" {
  source   = "../../../terraform-modules/gke-setup"
  settings = var.settings
  cluster  = "sandbox"
  color    = "green"
}

module "k8s-istio" {
  source                          = "../../../terraform-modules/k8s-istio"
  gke_cluster_connection_settings = module.gke-setup-green.gke_cluster_connection_settings
  settings                        = var.settings
  cluster                         = "sandbox"
  color                           = "green"
  depends_on                      = [module.gke-setup-green]
}

module "k8s-misc-operators" {
  source                          = "../../../terraform-modules/k8s-misc"
  gke_cluster_connection_settings = module.gke-setup-green.gke_cluster_connection_settings
  settings                        = var.settings
  cluster                         = "sandbox"
  color                           = "green"
  depends_on                      = [module.k8s-istio]
}
module "k8s-vault" {
  source                          = "../../../terraform-modules/k8s-vault"
  gke_cluster_connection_settings = module.gke-setup-green.gke_cluster_connection_settings
  settings                        = var.settings
  cluster                         = "sandbox"
  color                           = "green"
  oidc_discovery_url              = var.oidc_discovery_url
  oidc_client_id                  = var.oidc_client_id
  oidc_client_secret              = var.oidc_client_secret
  depends_on                      = [module.k8s-istio, module.k8s-misc-operators]
}
