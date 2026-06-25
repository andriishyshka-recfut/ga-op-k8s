provider "vault" {
  address = "https://vault.t.regemini.io"
}



terraform {
  backend "gcs" {
    bucket = "terraform-state-222"
    prefix = "tf-vault-policies/state"
  }
}
