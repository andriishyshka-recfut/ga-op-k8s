

# variable "Settings" {}
# variable "Cluster" {}
# variable "Color" {}

variable "DoRestoreFromBackup" {
  default = false
}
variable "GkeClusterConnectionSettings" {}

data "google_project" "current_project" {
}

locals {
  harborNs        = "harbor"
  currentProject  = split("/", data.google_project.current_project.id)[1]
  restoreSwitcher = var.DoRestoreFromBackup ? 1 : 0
  gkeClusterEndpoint      = var.GkeClusterConnectionSettings.HOST
  gkeBearerToken          = var.GkeClusterConnectionSettings.API_KEY
}
