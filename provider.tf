provider "google" {
  project = "terraform-k8s-spin-up"
  region  = "europe-west3"
  #zone    = "us-central1-c"
  version = "v3.19.0"
}

provider "google-beta" {
  project = "terraform-k8s-spin-up"
  region  = "europe-west3"
  #zone    = "us-central1-c"
  version = "v3.19.0"
}
