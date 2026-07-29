resource "google_compute_subnetwork" "net" {
  for_each                 = lookup(var.Settings, "additional_subnets", {})
  name                     = each.key
  ip_cidr_range            = each.value.cidr
  region                   = var.Settings.clusters[var.Cluster].region
  network                  = data.google_compute_network.vpc.self_link
  purpose                  = try(each.value.purpose, null)
  private_ip_google_access = try(each.value.private_ip_google_access, true)
}

resource "google_compute_address" "internal_ingress" {
  for_each     = lookup(var.Settings, "internal_static_ips", {})
  name         = "${each.key}-ingress"
  address_type = "INTERNAL"
  purpose      = "GCE_ENDPOINT"
  address      = each.value.ip
  subnetwork   = each.value.subnet
}
