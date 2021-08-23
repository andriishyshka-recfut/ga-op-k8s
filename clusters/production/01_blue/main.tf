

// should be set with tfvars
variable "Settings" {}
variable "VaultAddress" {}
variable "Cluster" {}
variable "OidcDiscoveryUrl" { default = "SAMPLE" }
variable "OidcClientId" { default = "SAMPLE" }
variable "OidcClientSecret" { default = "SAMPLE" }


module "gke-setup-blue" {
  source   = "../../../terraform-modules/gke-setup"
  Settings = var.Settings
  Cluster  = "production"
  Color    = "blue"
}

module "k8s-istio" {
  source                       = "../../../terraform-modules/k8s-istio"
  GkeClusterConnectionSettings = module.gke-setup-blue.GkeClusterConnectionSettings
  Settings                     = var.Settings
  Cluster                      = "production"
  Color                        = "blue"
  depends_on                   = [module.gke-setup-blue]
}


module "k8s-misc-operators" {
  source                       = "../../../terraform-modules/k8s-misc"
  GkeClusterConnectionSettings = module.gke-setup-blue.GkeClusterConnectionSettings
  Settings                     = var.Settings
  Cluster                      = "production"
  Color                        = "blue"
  depends_on                   = [module.k8s-istio]
}
module "k8s-vault" {
  source                       = "../../../terraform-modules/k8s-vault"
  GkeClusterConnectionSettings = module.gke-setup-blue.GkeClusterConnectionSettings
  Settings                     = var.Settings
  Cluster                      = "production"
  Color                        = "blue"
  OidcDiscoveryUrl             = var.OidcDiscoveryUrl
  OidcClientId                 = var.OidcClientId
  OidcClientSecret             = var.OidcClientSecret
  depends_on                   = [module.k8s-istio, module.k8s-misc-operators]
}

module "k8s-vault-tekton" {
  source                       = "../../../terraform-modules/k8s-vault-tekton"
  GkeClusterConnectionSettings = module.gke-setup-blue.GkeClusterConnectionSettings
  Cluster                      = "production"
  Color                        = "blue"
  VaultAddress = var.VaultAddress
  depends_on                   = [module.k8s-vault]
}
