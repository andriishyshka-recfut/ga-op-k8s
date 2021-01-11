provider "google" {
  # version = "v3.19.0"
}

terraform {
  backend "gcs" {
    bucket = "terraform-state-production111"
    prefix = "terraform-base/state"
  }
}
