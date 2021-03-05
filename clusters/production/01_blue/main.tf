
// should be set with tfvars
variable "Settings" {}
variable "OidcDiscoveryUrl" { default = "SAMPLE" }
variable "OidcClientId" { default = "SAMPLE" }
variable "OidcClientSecret" { default = "SAMPLE" }


module "gke-setup" {
  source   = "../../../terraform-modules/gke-setup"
  Settings = var.Settings
  Cluster  = "production"
  Color    = "blue"
}

module "k8s-istio" {
  source                       = "../../../terraform-modules/k8s-istio"
  GkeClusterConnectionSettings = module.gke-setup.GkeClusterConnectionSettings
  Settings                     = var.Settings
  Cluster                      = "production"
  Color                        = "blue"
  depends_on                   = [module.gke-setup]
}


module "k8s-namespaces" {
  source     = "../../../terraform-modules/k8s-namespaces"
  Settings   = var.Settings
  Cluster    = "production"
  Color      = "blue"
  depends_on = [module.k8s-istio]
}


module "k8s-misc-operators" {
  source                       = "../../../terraform-modules/k8s-misc"
  GkeClusterConnectionSettings = module.gke-setup.GkeClusterConnectionSettings
  Settings                     = var.Settings
  Cluster                      = "production"
  Color                        = "blue"
  depends_on                   = [module.k8s-istio, module.k8s-namespaces]
}

module "k8s-vault" {
  source                       = "../../../terraform-modules/k8s-vault"
  GkeClusterConnectionSettings = module.gke-setup.GkeClusterConnectionSettings
  Settings                     = var.Settings
  Cluster                      = "production"
  Color                        = "blue"
  OidcDiscoveryUrl             = var.OidcDiscoveryUrl
  OidcClientId                 = var.OidcClientId
  OidcClientSecret             = var.OidcClientSecret
  depends_on                   = [module.k8s-istio, module.k8s-misc-operators]
}
