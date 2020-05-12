provider "google" {
  project = "silent-eye-276318"
  region  = "us-east4"
  #zone    = "us-central1-c"
  version = "v3.19.0"
}

provider "google-beta" {
  project = "silent-eye-276318"
  region  = "us-east4"
  #zone    = "us-central1-c"
  version = "v3.19.0"
}

terraform {
  backend "gcs" {
    bucket  = "terraform-state-2222"
    prefix  = "terraform-infra/state"
  }
}
