
// should be set with tfvars
variable "Settings" {}
variable "VaultAddress" {}
variable "Cluster" {}
variable "OidcDiscoveryUrl" { default = "SAMPLE" }
variable "OidcClientId" { default = "SAMPLE" }
variable "OidcClientSecret" { default = "SAMPLE" }


module "gke-setup-red" {
  source   = "../../../terraform-modules/gke-red-setup"
  Settings = var.Settings
  Cluster  = "production"
  Color    = "red"
}

module "k8s-istio" {
  source                       = "../../../terraform-modules/k8s-istio"
  GkeClusterConnectionSettings = module.gke-setup-red.GkeClusterConnectionSettings
  Settings                     = var.Settings
  Cluster                      = "production"
  Color                        = "red"
  depends_on                   = [module.gke-setup-red]
}


module "k8s-misc-operators" {
  source                       = "../../../terraform-modules/k8s-misc"
  GkeClusterConnectionSettings = module.gke-setup-red.GkeClusterConnectionSettings
  Settings                     = var.Settings
  Cluster                      = "production"
  Color                        = "red"
  depends_on                   = [module.k8s-istio]
}
module "k8s-vault" {
  source                       = "../../../terraform-modules/k8s-vault-red"
  GkeClusterConnectionSettings = module.gke-setup-red.GkeClusterConnectionSettings
  Settings                     = var.Settings
  Cluster                      = "production"
  Color                        = "red"
  VaultAddress                 = var.VaultAddress
  depends_on                   = [module.k8s-istio, module.k8s-misc-operators]
}

module "k8s-vault-tekton" {
  source                       = "../../../terraform-modules/k8s-tekton-operator"
  GkeClusterConnectionSettings = module.gke-setup-red.GkeClusterConnectionSettings
  Cluster                      = "production"
  Color                        = "red"
  VaultAddress                 = var.VaultAddress
  # depends_on                   = [module.k8s-vault]
}

module "k8s-istio-lb" {
  source     = "../../../terraform-modules/k8s-istio-lb"
  Settings   = var.Settings
  Cluster    = "production"
  Color      = "red"
  depends_on = [module.k8s-istio]
}
