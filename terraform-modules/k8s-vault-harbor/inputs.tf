
variable "DoRestoreFromBackup" {
  default = false
}
variable "GkeClusterConnectionSettings" {}


locals {
  harborNs        = "harbor"
  # harborVersion   = var.Settings.clusters[var.Cluster].versions.harbor.version
  restoreSwitcher = var.DoRestoreFromBackup ? 1 : 0
  gkeClusterEndpoint      = var.GkeClusterConnectionSettings.HOST
  gkeBearerToken          = var.GkeClusterConnectionSettings.API_KEY
  }
