provider "vault" {
  address = "https://vault.p.regemini.io"
}

terraform {
  backend "gcs" {
    bucket = "terraform-state-production111"
    prefix = "tf-vault-policies/state"
  }
}
