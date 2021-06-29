
terraform {
  backend "gcs" {
    bucket = "terraform-state-222"
    prefix = "tf-backup/state-3"
  }
  required_providers {
    kubernetes = {
      version = "2.0.1"
    }
  }

}
