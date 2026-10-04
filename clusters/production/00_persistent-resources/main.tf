
terraform {
  backend "gcs" {
    bucket = "terraform-state-production111"
    prefix = "terraform-sandbox-persistent_resources/state"
  }
}

variable "Settings" {}
variable "Cluster" {}
variable "VaultAddress" {}
provider "google" {
  # version = "v3.19.0"
}

module "infra-persistent" {
  source             = "../../../terraform-modules/cluster-persistent-resources"
  Settings           = var.Settings
  Cluster            = "production"
  destination_ranges = {}

  # providers = {
  #   google = google
  # }
}

# module "dns" {
#   source   = "../../../terraform-modules/dns"
#   Settings = var.Settings
#   Cluster  = "production"
#
#   providers = {
#     google = google
#   }
# }
