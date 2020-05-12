resource "google_storage_bucket" "terraform-state" {
  name          = "terraform-state-2222"
  location      = var.region
}
