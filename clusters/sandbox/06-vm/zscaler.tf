
terraform {
  backend "gcs" {
    bucket = "terraform-state-222"
    prefix = "terraform-sandbox-zscaler-vm/state"
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
  Cluster      = "sandbox"
  VaultAddress = var.VaultAddress
}
