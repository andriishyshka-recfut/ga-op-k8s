
variable "region" {
  default = "europe-west3"
}


resource "google_compute_network" "vpc" {
  name = "vpc"
  auto_create_subnetworks = "false"
  routing_mode = "GLOBAL"
  delete_default_routes_on_create = "true"
}


resource "google_compute_subnetwork" "private" {
  name          = "test-subnetwork"
  ip_cidr_range = "172.27.0.0/24"
  region        = var.region
  network       = google_compute_network.vpc.self_link
  secondary_ip_range {
    range_name    = "tf-test-secondary-range-update1"
    ip_cidr_range = "192.168.1.0/24"
  }
}


resource "google_compute_router" "router" {
  name    = "router"
  region  = var.region
  network = google_compute_network.vpc.self_link

  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "nat" {
  name                               = "my-router-nat"
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
