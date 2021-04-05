
# data "google_project" "current_project" {
# }

data "google_client_config" "current" {}

locals {
  mongoNs         = "mongo"
  # currentProject  = split("/", data.google_project.current_project.id)[1]
  currentProject  = data.google_client_config.current.project
}

variable "CredsPath" {
  default = "secret/mongo/production"
}
