
terraform {
  backend "gcs" {
    bucket = "terraform-state-production111"
    prefix = "terraform-production-backups/urlscan-migration-02-06-2021"
  }
}
