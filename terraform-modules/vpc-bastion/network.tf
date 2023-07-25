
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
    "69.164.208.72/32", // - Outline VPN
    "35.242.253.39/32", // sandbox-old
    "78.26.204.32/32",  // stepan
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
    "35.188.246.238/32", // prod nat
    "34.85.254.253/32",  // prod nat
    "35.242.253.39/32",  // sandbox-old
    "35.196.5.12/32",    //app11.digaweb.com
    "35.185.38.145/32",  //app12.digaweb.com
    "34.74.154.117/32", //app13.digaweb.com
    "34.86.87.120/32",   // bastion test account
    "34.86.176.12/32",   // bastion test account
    "34.86.175.17/32",   //test account nat ip
    "78.26.204.32/32",
    "34.86.42.141",
    "34.145.147.71",    // new prod NATs
    "34.85.227.14",
    "35.245.99.252",
    "35.236.209.180",
    "34.86.23.117",
    "34.150.198.192",
    "35.245.167.217",
    "34.86.207.58",
    "35.186.173.184",
    "35.245.232.185",
    "${google_compute_address.envoy.address}/32",
  "${google_compute_address.wireguard.address}/32"]

  allow {
    protocol = "tcp"
    ports    = ["22", "443","32200-32204"]
  }

  target_tags = ["dmz"]
}

resource "google_compute_firewall" "bastion_cloudflare" {
  name      = "bastion-cloudflare"
  network   = google_compute_network.vpc.name
  direction = "INGRESS"
  source_ranges = [
    "173.245.48.0/20",
    "103.21.244.0/22",
    "103.22.200.0/22",
    "103.31.4.0/22",
    "141.101.64.0/18",
    "108.162.192.0/18",
    "190.93.240.0/20",
    "188.114.96.0/20",
    "197.234.240.0/22",
    "198.41.128.0/17",
    "162.158.0.0/15",
    "104.16.0.0/13",
    "104.24.0.0/14",
    "172.64.0.0/13",
  "131.0.72.0/22"]
  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  target_tags = ["dmz"]
}

resource "google_compute_firewall" "bastion_tor_proxy" {
  name      = "bastion-tor-proxy"
  network   = google_compute_network.vpc.name
  direction = "INGRESS"
  source_ranges = [
    "69.164.208.72/32",
    "78.46.86.231/32",
    "35.196.5.12/32",    //app11.digaweb.com
    "35.185.38.145/32",  //app12.digaweb.com
    "34.74.154.117/32", //app13.digaweb.com
    "138.201.188.166/32", //2captcha proxy gate
    "78.46.86.231/32", // anticaptcha
    "35.185.38.145/32",  // - Captcha resolver service
    "34.86.175.17/32",    //test account nat ip
    "35.188.246.238/32",  // prod nat
    "34.85.254.253/32",   // prod nat
    "${google_compute_address.envoy.address}/32",
  "${google_compute_address.wireguard.address}/32"]

  allow {
    protocol = "tcp"
    ports    = ["30000-30120"]
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
  name          = "bastion-vpn"
  network       = google_compute_network.wireguard.name
  direction     = "INGRESS"
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
