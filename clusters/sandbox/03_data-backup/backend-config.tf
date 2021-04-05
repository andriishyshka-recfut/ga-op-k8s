
terraform {
  backend "gcs" {
    bucket = "terraform-state-222"
    prefix = "tf-backup/state-2"
  }
  required_providers {
    kubernetes = {
      version = "2.0.1"
    }
  }

}
