
provider "google" {
}

variable "Settings" {}
variable "Cluster" {}
variable "VaultAddress" {}

terraform {
  backend "gcs" {
    bucket = "terraform-state-production111"
    prefix = "terraform-production-lb-switch/state"
  }
}

module "lb-switch" {
  source                       = "../../../terraform-modules/lb-switch"
  Settings                     = var.Settings
  Cluster                      = var.Cluster
}
