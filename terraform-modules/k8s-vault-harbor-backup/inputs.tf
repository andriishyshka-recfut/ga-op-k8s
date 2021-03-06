

data "google_client_config" "current" {}


locals {
  harborNs       = "harbor"
  currentProject  = data.google_client_config.current.project
}
