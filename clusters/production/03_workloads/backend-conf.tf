
terraform {
  backend "gcs" {
    bucket = "terraform-state-production111"
    prefix = "terraform-production-workloads/state-3"
  }
}
