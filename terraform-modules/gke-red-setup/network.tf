


resource "google_compute_subnetwork" "net" {
  name          = "${var.Cluster}-${var.Color}-subnetwork"
  ip_cidr_range = var.Settings.clusters[var.Cluster][var.Color].nodes_subnet_range
  region        = var.Settings.clusters[var.Cluster].region
  network       = data.google_compute_network.vpc.self_link
  // https://cloud.google.com/vpc/docs/configure-private-google-access
  private_ip_google_access = true
  dynamic "secondary_ip_range" {
    for_each = var.Settings.clusters[var.Cluster][var.Color].subnets
    content {
      range_name    = replace(secondary_ip_range.key, "_", "-")
      ip_cidr_range = secondary_ip_range.value
    }
  }
}




#https://istio.io/docs/setup/platform-setup/gke/
resource "google_compute_firewall" "master_to_cluster" {
  name          = "master-to-${var.Cluster}-${var.Color}"
  network       = data.google_compute_network.vpc.self_link
  direction     = "INGRESS"
  source_ranges = [var.Settings.clusters[var.Cluster][var.Color].master_ipv4_cidr_block]
  target_tags   = [var.Cluster]

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
  }

}



resource "google_compute_firewall" "bastion_to_cluster" {
  name        = "bastion-to-${var.Cluster}-${var.Color}"
  network     = data.google_compute_network.vpc.self_link
  direction   = "INGRESS"
  source_tags = ["dmz"]
  target_tags = [var.Cluster]

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22-1000", "6379", "8200", "9200", "30000-32767"]
  }

}
resource "google_compute_firewall" "cluster_to_cluster" {
  name        = "${var.Cluster}-to-${var.Cluster}-${var.Color}"
  network     = data.google_compute_network.vpc.self_link
  direction   = "INGRESS"
  source_tags = [var.Cluster]
  target_tags = [var.Cluster]

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
resource "google_compute_firewall" "cluster_to_bastion" {
  name          = "${var.Cluster}-${var.Color}-to-dmz"
  network       = data.google_compute_network.vpc.self_link
  direction     = "INGRESS"
  source_tags   = [var.Cluster]
  source_ranges = [var.Settings.clusters[var.Cluster][var.Color].subnets.pods_secondary_range]
  target_tags   = ["dmz"]

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }
}

resource "google_compute_firewall" "clusters_nodeport" {
  name          = "${var.Cluster}-${var.Color}-nodeports"
  network       = data.google_compute_network.vpc.self_link
  direction     = "INGRESS"
  source_ranges = [local.redPods]
  target_tags   = ["${var.Cluster}-${var.Color}"]

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["30000-32767", "27017"]
  }
}
