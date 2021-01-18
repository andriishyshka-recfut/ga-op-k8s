
data "google_compute_network" "vpc" {
  name = var.Settings.vpc_name
}


data "google_compute_instance" "bastion" {
  name = var.Settings.bastion_hostname
  zone = var.Settings.bastion_zone
}

variable "Settings" {}
variable "Cluster" {}

resource "google_dns_managed_zone" "k8s_zone" {
  count       = lookup(var.Settings.clusters[var.Cluster].blue, "color", "blanc") == "blue" ? 1 : 0
  name        = "${var.Settings.clusters[var.Cluster].subdomain}-private-zone"
  dns_name    = "${var.Settings.clusters[var.Cluster].subdomain}.${var.Settings.clusters[var.Cluster].domain}."
  description = "DNS zone for ${var.Settings.clusters[var.Cluster].subdomain} k8s cluster"
  visibility  = "private"

  private_visibility_config {
    networks {
      network_url = data.google_compute_network.vpc.self_link
    }
  }
}

resource "google_dns_record_set" "wildcard" {
  count = lookup(var.Settings.clusters[var.Cluster].blue, "color", "blanc") == "blue" ? 1 : 0
  name  = "*.${google_dns_managed_zone.k8s_zone[count.index].dns_name}"
  type  = "A"
  ttl   = 300

  managed_zone = google_dns_managed_zone.k8s_zone[count.index].name

  rrdatas = [data.google_compute_instance.bastion.network_interface.0.network_ip]
}
