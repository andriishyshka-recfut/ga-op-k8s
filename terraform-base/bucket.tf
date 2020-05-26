resource "google_storage_bucket" "terraform-state" {
  name          = "terraform-state-222"
  location      = var.region
  lifecycle {
    prevent_destroy = true
  }
}
