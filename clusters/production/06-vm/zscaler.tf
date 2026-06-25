
terraform {
  backend "gcs" {
    bucket = "terraform-state-production111"
    prefix = "terraform-production-zscaler-vm/state"
  }
}

variable "Settings" {}
variable "VaultAddress" {}

provider "google" {
  # version = "v3.19.0"
}

provider "vault" {
  address = var.VaultAddress
}

module "zscaler_vm" {
  source       = "../../../terraform-modules/gcp-zscaler-vm"
  Settings     = var.Settings
  Cluster      = "production"
  VaultAddress = var.VaultAddress
}
