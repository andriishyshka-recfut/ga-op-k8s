
data "google_compute_network" "vpc" {
  name = var.settings.vpc_name
}


data "google_compute_instance" "bastion" {
  name = var.settings.bastion_hostname
  zone = var.settings.bastion_zone
}

variable "settings" {}
variable "cluster" {}

resource "google_dns_managed_zone" "k8s-zone" {
  count       = lookup(var.settings[var.cluster], "color", "blanc") == "blue" ? 1 : 0
  name        = "${var.settings[var.cluster].subdomain}-private-zone"
  dns_name    = "${var.settings[var.cluster].subdomain}.${var.settings[var.cluster].domain}."
  description = "DNS zone for ${var.settings[var.cluster].subdomain} k8s cluster"
  visibility  = "private"

  private_visibility_config {
    networks {
      network_url = data.google_compute_network.vpc.self_link
    }
  }
}

resource "google_dns_record_set" "wildcard" {
  count = lookup(var.settings[var.cluster], "color", "blanc") == "blue" ? 1 : 0
  name  = "*.${google_dns_managed_zone.k8s-zone[count.index].dns_name}"
  type  = "A"
  ttl   = 300

  managed_zone = google_dns_managed_zone.k8s-zone[count.index].name

  rrdatas = [data.google_compute_instance.bastion.network_interface.0.network_ip]
}
