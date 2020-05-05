provider "google" {
  project = "test-terraform3"
  region  = "europe-west3"
  #zone    = "us-central1-c"
  version = "v3.19.0"
}

provider "google-beta" {
  project = "test-terraform3"
  region  = "europe-west3"
  #zone    = "us-central1-c"
  version = "v3.19.0"
}

terraform {
  backend "gcs" {
    bucket  = "terraform-state-111"
    prefix  = "terraform-infra/state"
  }
}
