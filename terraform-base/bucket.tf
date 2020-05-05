resource "google_storage_bucket" "terraform-state" {
  name          = "terraform-state-111"
  location      = var.region
}
