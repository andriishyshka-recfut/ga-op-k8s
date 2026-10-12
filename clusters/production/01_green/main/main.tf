
// should be set with tfvars
variable "Settings" {}
variable "VaultAddress" {}
variable "Cluster" {}
variable "OidcDiscoveryUrl" { default = "SAMPLE" }
variable "OidcClientId" { default = "SAMPLE" }
variable "OidcClientSecret" { default = "SAMPLE" }
variable "GkeClusterConnectionSettings" {}

locals {
  GkeClusterConnectionSettings = jsondecode(var.GkeClusterConnectionSettings)
  tektonResources              = ["task.yaml", "pipeline.yaml", "pipelinerun.yaml", "bots.yaml", "pods-cleanup.yaml", "telegram.yaml"]

}

module "k8s-istio" {
  source                       = "../../../../terraform-modules/k8s-istio"
  GkeClusterConnectionSettings = local.GkeClusterConnectionSettings
  Settings                     = var.Settings
  Cluster                      = "production"
  Color                        = "green"
}

module "k8s-misc-operators" {
  source                       = "../../../../terraform-modules/k8s-misc"
  GkeClusterConnectionSettings = local.GkeClusterConnectionSettings
  Settings                     = var.Settings
  Cluster                      = "production"
  Color                        = "green"
  depends_on                   = [module.k8s-istio]
}

module "k8s-vault" {
  source                       = "../../../../terraform-modules/k8s-vault"
  GkeClusterConnectionSettings = local.GkeClusterConnectionSettings
  Settings                     = var.Settings
  Cluster                      = "production"
  Color                        = "green"
  OidcDiscoveryUrl             = var.OidcDiscoveryUrl
  OidcClientId                 = var.OidcClientId
  OidcClientSecret             = var.OidcClientSecret
  VaultAddress                 = var.VaultAddress
  depends_on                   = [module.k8s-istio, module.k8s-misc-operators]
}

module "k8s-vault-tekton" {
  source                       = "../../../../terraform-modules/k8s-vault-tekton"
  GkeClusterConnectionSettings = local.GkeClusterConnectionSettings
  Cluster                      = "production"
  Color                        = "green"
  Settings                     = var.Settings
  VaultAddress                 = var.VaultAddress
  depends_on                   = [module.k8s-vault]
}

module "k8s-vault-tekton-resources" {
  source     = "../../../../terraform-modules/k8s-vault-tekton-resources"
  Settings   = var.Settings
  Resources  = local.tektonResources
  depends_on = [module.k8s-vault-tekton]
}
