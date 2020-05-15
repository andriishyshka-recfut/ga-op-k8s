provider "google" {
  version = "v3.19.0"
}

provider "google-beta" {
  version = "v3.19.0"
}

terraform {
  backend "gcs" {
    bucket  = "terraform-state-2222"
    prefix  = "terraform-infra/state"
  }
}

variable "cluster" {
  default = "infra"
}
