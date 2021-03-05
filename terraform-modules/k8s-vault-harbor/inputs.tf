

# variable "Settings" {}
# variable "Cluster" {}
# variable "Color" {}

variable "DoRestoreFromBackup" {
  default = false
}
variable "GkeClusterConnectionSettings" {}

data "google_client_config" "current" {}

locals {
  harborNs        = "harbor"
  restoreSwitcher = var.DoRestoreFromBackup ? 1 : 0
  gkeClusterEndpoint      = var.GkeClusterConnectionSettings.HOST
  gkeBearerToken          = var.GkeClusterConnectionSettings.API_KEY
  currentProject  = data.google_client_config.current.project
}
