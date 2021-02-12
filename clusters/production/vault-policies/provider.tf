
provider "vault" {
  address = "https://vault.p.digaweb.com"
}



terraform {
  backend "gcs" {
    bucket = "terraform-state-production111"
    prefix = "tf-vault-policies/state"
  }
}
