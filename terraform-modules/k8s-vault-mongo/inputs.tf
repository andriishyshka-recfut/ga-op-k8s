
data "google_project" "current_project" {
}

locals {
  mongoNs         = "mongo"
  currentProject  = split("/", data.google_project.current_project.id)[1]
  restoreSwitcher = var.DoRestoreFromBackup ? 1 : 0
}

variable "CredsPath" {
  default = "secret/mongo/production"
}

variable "DoRestoreFromBackup" {
  default = false
}
