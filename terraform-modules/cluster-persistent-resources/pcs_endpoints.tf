resource "google_compute_forwarding_rule" "psc_endpoint" {
  for_each = lookup(var.Settings, "psc_endpoints", {})

  name                  = each.key
  region                = var.Settings.clusters[var.Cluster].region
  network               = data.google_compute_network.vpc.id
  ip_address            = google_compute_address.internal_ingress[each.value.ip_link].id
  target                = each.value.target
  load_balancing_scheme = ""
}