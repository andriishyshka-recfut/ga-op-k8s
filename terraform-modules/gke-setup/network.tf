


resource "google_compute_subnetwork" "net" {
  name          = "${var.cluster}-subnetwork"
  ip_cidr_range = var.settings.cluster_settings[var.cluster].nodes_subnet_range
  region        = var.settings.cluster_settings[var.cluster].region
  network       = data.google_compute_network.vpc.self_link
  // https://cloud.google.com/vpc/docs/configure-private-google-access
  private_ip_google_access  = true
  secondary_ip_range {
    range_name    = "pods-secondary-range"
    ip_cidr_range = var.settings.cluster_settings[var.cluster].pods_subnet_range
  }
  secondary_ip_range {
    range_name    = "services-secondary-range"
    ip_cidr_range = var.settings.cluster_settings[var.cluster].services_subnet_range
  }
}


resource "google_dns_managed_zone" "k8s-zone" {
  name        = "${var.settings.cluster_settings[var.cluster].subdomain}-private-zone"
  dns_name    = "${var.settings.cluster_settings[var.cluster].subdomain}.${var.settings.cluster_settings[var.cluster].domain}."
  description = "DNS zone for ${var.settings.cluster_settings[var.cluster].subdomain} k8s cluster"
  visibility = "private"

  private_visibility_config {
    networks {
      network_url = data.google_compute_network.vpc.self_link
    }
  }
}

resource "google_dns_record_set" "wildcard" {
  name = "*.${google_dns_managed_zone.k8s-zone.dns_name}"
  type = "A"
  ttl  = 300

  managed_zone = google_dns_managed_zone.k8s-zone.name

  rrdatas = [data.google_compute_instance.bastion.network_interface.0.network_ip]
}


#https://istio.io/docs/setup/platform-setup/gke/
resource "google_compute_firewall" "master-to-cluster" {
  name          = "master-to-${var.cluster}"
  network       = data.google_compute_network.vpc.self_link
  direction     = "INGRESS"
  source_ranges = [ var.settings.cluster_settings[var.cluster].master_ipv4_cidr_block ]
  target_tags = ["${var.cluster}"]

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
  }

}

resource "google_compute_firewall" "bastion-to-cluster" {
  name          = "bastion-to-${var.cluster}"
  network       = data.google_compute_network.vpc.self_link
  direction     = "INGRESS"
  source_tags = ["dmz"]
  target_tags = ["${var.cluster}"]

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22-1000","30000-32767"]
  }

}
resource "google_compute_firewall" "cluster-to-cluster" {
  name          = "${var.cluster}-to-${var.cluster}"
  network       = data.google_compute_network.vpc.self_link
  direction     = "INGRESS"
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
