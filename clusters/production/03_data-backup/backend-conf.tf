
terraform {
  backend "gcs" {
    bucket = "terraform-state-production111"
    prefix = "terraform-production-backups/state-4"
  }
}
