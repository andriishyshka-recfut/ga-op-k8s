variable "Color" {}

provider "google" {
}

provider "vault" {
  address = "https://vault.p.regemini.io"
}

terraform {
  backend "gcs" {
    bucket = "terraform-state-orbital-wording-233917"
    prefix = "terraform-minio-iam/state"
  }
}
