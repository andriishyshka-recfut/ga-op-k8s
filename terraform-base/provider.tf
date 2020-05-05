provider "google" {
  project = "test-terraform2"
  region  = "europe-west3"
  #zone    = "us-central1-c"
  version = "v3.19.0"
}

terraform {
  backend "gcs" {
    bucket  = "terraform-state-test112"
    prefix  = "terraform-base/state"
  }
}
