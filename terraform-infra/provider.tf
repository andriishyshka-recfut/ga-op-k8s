provider "google" {
  project = "ardent-rarity-239115"
  region  = "us-east4"
  #zone    = "us-central1-c"
  version = "v3.19.0"
}

provider "google-beta" {
  project = "ardent-rarity-239115"
  region  = "us-east4"
  #zone    = "us-central1-c"
  version = "v3.19.0"
}

terraform {
  backend "gcs" {
    bucket  = "terraform-state-222"
    prefix  = "terraform-infra/state"
  }
}
