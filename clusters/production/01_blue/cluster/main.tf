
// should be set with tfvars
variable "Settings" {}
variable "VaultAddress" {}
variable "Cluster" {}
variable "OidcDiscoveryUrl" { default = "SAMPLE" }
variable "OidcClientId" { default = "SAMPLE" }
variable "OidcClientSecret" { default = "SAMPLE" }


module "gke-setup-green" {
  source        = "../../../../terraform-modules/gke-setup"
  Settings      = var.Settings
  Cluster       = "production"
  Color         = "blue"
  ClusterColors = var.Settings.clusters.production.clusterColors
}

output "GkeClusterConnectionSettings" {
  value     = module.gke-setup-green.GkeClusterConnectionSettings
  sensitive = true
}
