provider "google" {
  version = "v3.19.0"
}

terraform {
  backend "gcs" {
    bucket  = "terraform-state-222"
    prefix  = "terraform-base/state"
  }
}
