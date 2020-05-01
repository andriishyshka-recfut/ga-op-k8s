
variable "region" {
  default = "europe-west3"
}


resource "google_compute_network" "vpc" {
  name = "vpc"
  auto_create_subnetworks = "false"
  routing_mode = "GLOBAL"
  delete_default_routes_on_create = "true"
}


resource "google_compute_subnetwork" "net" {
  name          = "test-subnetwork"
  ip_cidr_range = "172.27.0.0/22"
  region        = var.region
  network       = google_compute_network.vpc.self_link
  // https://cloud.google.com/vpc/docs/configure-private-google-access
  private_ip_google_access  = true
  secondary_ip_range {
    range_name    = "cluster-secondary-range"
    ip_cidr_range = "192.168.0.0/22"
  }
  secondary_ip_range {
    range_name    = "services-secondary-range"
    ip_cidr_range = "192.168.4.0/22"
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

resource "google_compute_firewall" "bastion-ssh" {
  name          = "bastion-ssh"
  network       = google_compute_network.vpc.name
  direction     = "INGRESS"
  source_ranges = ["78.26.204.32/32"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  target_tags = ["dmz"]
}

resource "google_compute_firewall" "bastion-to-infra" {
  name          = "bastion-to-infra"
  network       = google_compute_network.vpc.name
  direction     = "INGRESS"
  source_tags = ["dmz"]
  target_tags = ["infra"]

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22-10000"]
  }

}


resource "google_compute_route" "default" {
  name         = "default"
  dest_range   = "0.0.0.0/0"
  network      = google_compute_network.vpc.name
  next_hop_gateway = "default-internet-gateway"
  priority     = 1000
  #tags = ["dmz","infra"]
}
