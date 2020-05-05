

resource "google_compute_network" "vpc" {
  name = module.common-vars.vpc_name
  auto_create_subnetworks = "false"
  routing_mode = "GLOBAL"
  delete_default_routes_on_create = "true"
  depends_on = [
    google_project_iam_member.service-account
  ]
}


resource "google_compute_subnetwork" "net" {
  name          = "dmz-subnetwork"
  ip_cidr_range = module.common-vars.bastion_subnet_range
  region        = var.region
  network       = google_compute_network.vpc.self_link
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
  //source_ranges = ["78.26.204.32/32"]
  source_ranges = ["78.26.204.32/32","69.164.208.72/32","35.185.38.145/32"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  target_tags = ["dmz"]
}

resource "google_compute_firewall" "bastion-vpn" {
  name          = "bastion-ssh"
  network       = google_compute_network.vpc.name
  direction     = "INGRESS"
  //source_ranges = ["78.26.204.32/32"]
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "tcp"
    ports    = ["19595","17806"]
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
    ports    = ["22-1000","30000-32767"]
  }

}


resource "google_compute_route" "dmz-default" {
  name         = "dmz-default"
  dest_range   = "0.0.0.0/0"
  network      = google_compute_network.vpc.name
  next_hop_gateway = "default-internet-gateway"
  priority     = 1000
  // We should have this route for all becouse I can't find how to tag GKE cluster to use this route during provisioning
  //tags = ["dmz"]
}
