locals {
  ip_count = 13
  nat_ips = [ for count_name in range(0,local.ip_count,1) : data.google_compute_address.ip_address[count_name].address]
}

resource "google_compute_address" "ip_address" {
  count = local.ip_count
  name = "nat-${count.index}"
  address_type = "EXTERNAL"
  ip_version = "IPV4"
  labels = {
    type = "nat"
  }
}

data "google_compute_address" "ip_address" {
  count = local.ip_count
  name = "nat-${count.index}"
  depends_on = [
    google_compute_address.ip_address
  ]
}

resource "google_compute_router_nat" "nat" {
  name   = "new-nat"
  router = "router"
  region = "us-east4"

  nat_ip_allocate_option = "MANUAL_ONLY"
  nat_ips                = google_compute_address.ip_address.*.self_link

  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  subnetwork {
    name                    = "migration"
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  rules {
    rule_number = 65000
    description = "Fake rule, wait for next DR to change to 0.0.0.0/0"
    match       = "inIpRange(destination.ip, '23.109.138.188/32')"
  }

  enable_endpoint_independent_mapping = false
}

output "nat-ips" {
  value = local.nat_ips
}