resource "google_storage_bucket" "terraform-state" {
  name          = "terraform-state-test112"
  location      = var.region
}
