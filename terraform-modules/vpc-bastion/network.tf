

resource "google_compute_network" "vpc" {
  name                            = var.Settings.vpc_name
  auto_create_subnetworks         = "false"
  routing_mode                    = "GLOBAL"
  delete_default_routes_on_create = "true"
  depends_on = [
    google_project_iam_member.service_account
  ]
}

resource "google_compute_network" "wireguard" {
  name                            = "wireguard"
  auto_create_subnetworks         = "false"
  routing_mode                    = "GLOBAL"
  delete_default_routes_on_create = "true"
  depends_on = [
    google_project_iam_member.service_account
  ]
}


resource "google_compute_subnetwork" "envoy" {
  name          = "envoy"
  ip_cidr_range = var.Settings.envoy_subnet_range
  region        = var.Region
  network       = google_compute_network.vpc.self_link
}

resource "google_compute_subnetwork" "wireguard" {
  name          = "wireguard"
  ip_cidr_range = var.Settings.wireguard_subnet_range
  region        = var.Region
  network       = google_compute_network.wireguard.self_link
}

resource "google_compute_router" "router" {
  name    = "router"
  region  = var.Region
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


resource "google_compute_firewall" "wireguard_https" {
  name      = "wireguard-https"
  network   = google_compute_network.wireguard.name
  direction = "INGRESS"
  source_ranges = [
    "69.164.208.72/32",  // - Outline VPN
    "35.242.253.39/32",  // sandbox-old
    "78.26.204.32/32", // stepan
    "${google_compute_address.envoy.address}/32",
    "${google_compute_address.wireguard.address}/32"]

  allow {
    protocol = "tcp"
    ports    = ["22", "443"]
  }

  target_tags = ["dmz"]
}


resource "google_compute_firewall" "bastion_ssh_https" {
  name      = "bastion-ssh-https"
  network   = google_compute_network.vpc.name
  direction = "INGRESS"
  source_ranges = [
    "69.164.208.72/32",  // - Outline VPN
    "35.185.38.145/32",  // - Captcha resolver service
    "35.245.245.168/32", // test account default VPC nat - access from gitlab jobs
    "35.188.246.238/32", // prod nat
    "35.242.253.39/32",  // sandbox-old
    "35.196.5.12/32",    //app11.digaweb.com
    "35.185.38.145/32",  //app12.digaweb.com
    "34.86.87.120/32",   // bastion test account
    "34.86.176.12/32",   // bastion test account
    "78.26.204.32/32", // stepan
    "${google_compute_address.envoy.address}/32",
    "${google_compute_address.wireguard.address}/32"]

  allow {
    protocol = "tcp"
    ports    = ["22", "443"]
  }

  target_tags = ["dmz"]
}
resource "google_compute_firewall" "bastion_tor_proxy" {
  name          = "bastion-tor-proxy"
  network       = google_compute_network.vpc.name
  direction     = "INGRESS"
  source_ranges = ["78.26.204.32/32",
                   "69.164.208.72/32",
                   "78.46.86.231/32",
                   "${google_compute_address.envoy.address}/32",
                   "${google_compute_address.wireguard.address}/32"  ]

  allow {
    protocol = "tcp"
    ports    = ["30000-30020"]
  }

  target_tags = ["dmz"]
}
// Let's Encrypt require direct access from all ips
resource "google_compute_firewall" "bastion_http" {
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

resource "google_compute_firewall" "bastion_http2" {
  name          = "wireguard-http"
  network       = google_compute_network.wireguard.name
  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  target_tags = ["dmz"]
}

resource "google_compute_firewall" "bastion_vpn" {
  name      = "bastion-vpn"
  network   = google_compute_network.wireguard.name
  direction = "INGRESS"
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "udp"
    ports    = ["51820"]
  }

  target_tags = ["dmz"]
}


resource "google_compute_route" "dmz_default" {
  name             = "dmz-default"
  dest_range       = "0.0.0.0/0"
  network          = google_compute_network.vpc.name
  next_hop_gateway = "default-internet-gateway"
  priority         = 1000
}
resource "google_compute_route" "dmz_default_wireguard" {
  name             = "default-wireguard"
  dest_range       = "0.0.0.0/0"
  network          = google_compute_network.wireguard.name
  next_hop_gateway = "default-internet-gateway"
  priority         = 1000
}
