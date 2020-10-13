


resource "google_compute_subnetwork" "net" {
  name          = "${var.cluster}-subnetwork"
  ip_cidr_range = var.settings.clusters[var.cluster][var.color].nodes_subnet_range
  region        = var.settings.clusters[var.cluster].region
  network       = data.google_compute_network.vpc.self_link
  // https://cloud.google.com/vpc/docs/configure-private-google-access
  private_ip_google_access = true
  secondary_ip_range {
    range_name    = "pods-secondary-range"
    ip_cidr_range = var.settings.clusters[var.cluster][var.color].pods_subnet_range
  }
  secondary_ip_range {
    range_name    = "services-secondary-range"
    ip_cidr_range = var.settings.clusters[var.cluster][var.color].services_subnet_range
  }
}




#https://istio.io/docs/setup/platform-setup/gke/
resource "google_compute_firewall" "master-to-cluster" {
  name          = "master-to-${var.cluster}"
  network       = data.google_compute_network.vpc.self_link
  direction     = "INGRESS"
  source_ranges = [var.settings.clusters[var.cluster][var.color].master_ipv4_cidr_block]
  target_tags   = ["${var.cluster}", "infra"]

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
  }

}



resource "google_compute_firewall" "bastion-to-cluster" {
  name        = "bastion-to-${var.cluster}"
  network     = data.google_compute_network.vpc.self_link
  direction   = "INGRESS"
  source_tags = ["dmz", "infra"]
  target_tags = [var.cluster]

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22-1000", "30000-32767"]
  }

}
resource "google_compute_firewall" "cluster-to-cluster" {
  name        = "${var.cluster}-to-${var.cluster}"
  network     = data.google_compute_network.vpc.self_link
  direction   = "INGRESS"
  source_tags = ["${var.cluster}"]
  target_tags = ["${var.cluster}"]

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
  }
  allow {
    protocol = "udp"
  }

}
# Required for vault integration and other services
resource "google_compute_firewall" "cluster-to-bastion" {
  name          = "${var.cluster}-to-dmz"
  network       = data.google_compute_network.vpc.self_link
  direction     = "INGRESS"
  source_tags   = ["${var.cluster}"]
  source_ranges = [var.settings.clusters[var.cluster][var.color].pods_subnet_range]
  target_tags   = ["dmz"]

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }
}
