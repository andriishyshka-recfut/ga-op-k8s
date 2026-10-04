resource "google_compute_address" "ip_address" {
  count        = local.ip_count
  name         = "nat-${count.index}"
  address_type = "EXTERNAL"
  ip_version   = "IPV4"
  labels = {
    type = "nat"
  }
}

data "google_compute_address" "ip_address" {
  count = local.ip_count
  name  = "nat-${count.index}"
  depends_on = [
    google_compute_address.ip_address
  ]
}