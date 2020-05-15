


resource "google_compute_subnetwork" "net" {
  name          = "infra-subnetwork"
  ip_cidr_range = module.common-vars.cluster_settings[var.cluster].nodes_subnet_range
  region        = var.region
  network       = data.google_compute_network.vpc.self_link
  // https://cloud.google.com/vpc/docs/configure-private-google-access
  private_ip_google_access  = true
  secondary_ip_range {
    range_name    = "pods-secondary-range"
    ip_cidr_range = module.common-vars.cluster_settings[var.cluster].pods_subnet_range
  }
  secondary_ip_range {
    range_name    = "services-secondary-range"
    ip_cidr_range = module.common-vars.cluster_settings[var.cluster].services_subnet_range
  }
}


resource "google_dns_managed_zone" "k8s-zone" {
  name        = "${module.common-vars.cluster_settings[var.cluster].subdomain}-private-zone"
  dns_name    = "${module.common-vars.cluster_settings[var.cluster].subdomain}.${module.common-vars.cluster_settings[var.cluster].domain}."
  description = "DNS zone for ${module.common-vars.cluster_settings[var.cluster].subdomain} k8s cluster"
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
