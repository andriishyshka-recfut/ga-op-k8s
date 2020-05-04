


resource "google_compute_subnetwork" "net" {
  name          = "test-subnetwork"
  ip_cidr_range = module.common-vars.infra_nodes_subnet_range
  region        = var.region
  network       = data.google_compute_network.vpc.self_link
  // https://cloud.google.com/vpc/docs/configure-private-google-access
  private_ip_google_access  = true
  secondary_ip_range {
    range_name    = "pods-secondary-range"
    ip_cidr_range = module.common-vars.infra_pods_subnet_range
  }
  secondary_ip_range {
    range_name    = "services-secondary-range"
    ip_cidr_range = module.common-vars.infra_services_subnet_range
  }
}
