resource "google_storage_bucket" "terraform-state" {
  name          = "terraform-state-test111"
  location      = var.region
}
