
provider "vault" {
  address = "https://vault.infra.digaweb.com"
}



terraform {
  backend "gcs" {
    bucket = "terraform-state-222"
    prefix = "tf-vault-policies/state"
  }
}
