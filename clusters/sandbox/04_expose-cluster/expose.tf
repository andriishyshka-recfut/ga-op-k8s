
provider "google" {
}

variable "Settings" {}
variable "VaultAddress" {}
variable "Cluster" {}




terraform {
  backend "gcs" {
    bucket = "terraform-state-222"
    prefix = "tf-lb-switch/state-4"
  }

}

module "lb-switch" {
  source   = "../../../terraform-modules/lb-switch"
  Settings = var.Settings
  Cluster  = "sandbox"

}
