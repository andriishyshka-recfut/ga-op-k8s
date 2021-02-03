
// should be set with tfvars
variable "Settings" {}
variable "OidcDiscoveryUrl" { default = "SAMPLE" }
variable "OidcClientId" { default = "SAMPLE" }
variable "OidcClientSecret" { default = "SAMPLE" }


module "gke-setup-green" {
  source   = "../../../terraform-modules/gke-setup"
  Settings = var.Settings
  Cluster  = "sandbox"
  Color    = "green"
}

module "k8s-istio" {
  source                       = "../../../terraform-modules/k8s-istio"
  GkeClusterConnectionSettings = module.gke-setup-green.GkeClusterConnectionSettings
  Settings                     = var.Settings
  Cluster                      = "sandbox"
  Color                        = "green"
  depends_on                   = [module.gke-setup-green]
}


module "k8s-misc-operators" {
  source                       = "../../../terraform-modules/k8s-misc"
  GkeClusterConnectionSettings = module.gke-setup-green.GkeClusterConnectionSettings
  Settings                     = var.Settings
  Cluster                      = "sandbox"
  Color                        = "green"
  depends_on                   = [module.k8s-istio]
}
module "k8s-vault" {
  source                       = "../../../terraform-modules/k8s-vault"
  GkeClusterConnectionSettings = module.gke-setup-green.GkeClusterConnectionSettings
  Settings                     = var.Settings
  Cluster                      = "sandbox"
  Color                        = "green"
  OidcDiscoveryUrl             = var.OidcDiscoveryUrl
  OidcClientId                 = var.OidcClientId
  OidcClientSecret             = var.OidcClientSecret
  depends_on                   = [module.k8s-istio, module.k8s-misc-operators]
}
