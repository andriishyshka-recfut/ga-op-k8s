
// should be set with tfvars
variable "Settings" {}
variable "VaultAddress" {}
variable "OidcDiscoveryUrl" { default = "SAMPLE" }
variable "OidcClientId" { default = "SAMPLE" }
variable "OidcClientSecret" { default = "SAMPLE" }


module "gke-setup-green" {
  source        = "../../../../terraform-modules/gke-setup"
  Settings      = var.Settings
  Cluster       = "sandbox"
  Color         = "green"
  ClusterColors = var.Settings.clusters.sandbox.clusterColors
}

output "GkeClusterConnectionSettings" {
  value     = module.gke-setup-green.GkeClusterConnectionSettings
  sensitive = true
}

