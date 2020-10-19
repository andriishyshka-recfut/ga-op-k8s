
terraform {
  backend "gcs" {
    bucket = "terraform-state-222"
    prefix = "terraform-sandbox-persistent_resources/state"
  }
}

variable "settings" {}
provider "google" {
  # version = "v3.19.0"
}

module "infra-persistent" {
  source   = "../../../terraform-modules/cluster-persistent-resources"
  settings = var.settings
  cluster  = "sandbox"

  providers = {
    google = google
  }
}

module "dns" {
  source   = "../../../terraform-modules/dns"
  settings = var.settings
  cluster  = "sandbox"

  providers = {
    google = google
  }
}
