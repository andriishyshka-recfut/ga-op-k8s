
variable "BackupSettings" { }
variable "Cluster" {}
variable "Color" {}
data "google_project" "current_project" {
}

locals {
  mongoNs        = "mongo"
  currentProject = split("/", data.google_project.current_project.id)[1]
}
