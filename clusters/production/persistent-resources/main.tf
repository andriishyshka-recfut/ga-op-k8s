
terraform {
  backend "gcs" {
    bucket = "terraform-state-production111"
    prefix = "terraform-sandbox-persistent_resources/state"
  }
}

variable "Settings" {}
provider "google" {
  # version = "v3.19.0"
}

module "infra-persistent" {
  source   = "../../../terraform-modules/cluster-persistent-resources"
  Settings = var.Settings
  Cluster  = "sandbox"

  providers = {
    google = google
  }
}

module "dns" {
  source   = "../../../terraform-modules/dns"
  Settings = var.Settings
  Cluster  = "sandbox"

  providers = {
    google = google
  }
}
