

resource "google_compute_network" "vpc" {
  name                            = var.settings.vpc_name
  auto_create_subnetworks         = "false"
  routing_mode                    = "GLOBAL"
  delete_default_routes_on_create = "true"
  depends_on = [
    google_project_iam_member.service-account
  ]
}


resource "google_compute_subnetwork" "net" {
  name          = "dmz-subnetwork"
  ip_cidr_range = var.settings.bastion_subnet_range
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

resource "google_compute_firewall" "bastion-ssh-https" {
  name      = "bastion-ssh-https"
  network   = google_compute_network.vpc.name
  direction = "INGRESS"
  //source_ranges = ["78.26.204.32/32"]
  source_ranges = ["78.26.204.32/32", "69.164.208.72/32", "35.185.38.145/32", "${google_compute_address.static.address}/32"]

  allow {
    protocol = "tcp"
    ports    = ["22", "443"]
  }

  target_tags = ["dmz"]
}
resource "google_compute_firewall" "bastion-tor-proxy" {
  name      = "bastion-tor-proxy"
  network   = google_compute_network.vpc.name
  direction = "INGRESS"
  //source_ranges = ["78.26.204.32/32"]
  source_ranges = ["78.26.204.32/32", "69.164.208.72/32", "78.46.86.231/32", "${google_compute_address.static.address}/32", ]

  allow {
    protocol = "tcp"
    ports    = ["30000-30020"]
  }

  target_tags = ["dmz"]
}
// Let's Encrypt require direct access from all ips
resource "google_compute_firewall" "bastion-http" {
  name          = "bastion-http"
  network       = google_compute_network.vpc.name
  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  target_tags = ["dmz"]
}

resource "google_compute_firewall" "bastion-vpn" {
  name      = "bastion-vpn"
  network   = google_compute_network.vpc.name
  direction = "INGRESS"
  //source_ranges = ["78.26.204.32/32"]
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "udp"
    ports    = ["51820"]
  }

  target_tags = ["dmz"]
}


resource "google_compute_route" "dmz-default" {
  name             = "dmz-default"
  dest_range       = "0.0.0.0/0"
  network          = google_compute_network.vpc.name
  next_hop_gateway = "default-internet-gateway"
  priority         = 1000
  // We should have this route for all becouse I can't find how to tag GKE cluster to use this route during provisioning
  //tags = ["dmz"]
}
