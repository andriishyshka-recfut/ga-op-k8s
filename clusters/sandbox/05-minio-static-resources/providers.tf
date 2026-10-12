variable "Color" {}

provider "google" {
}

provider "vault" {
  address = "https://vault.t.regemini.io"
}

terraform {
  backend "gcs" {
    bucket = "terraform-state-ardent-rarity-239115"
    prefix = "terraform-minio-iam/state"
  }
}
