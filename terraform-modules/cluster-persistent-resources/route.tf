resource "google_compute_router_nat" "nat" {
  for_each = lookup(var.Settings, "nat", {})
  name     = each.key
  router   = "router"
  region   = "us-east4"

  nat_ip_allocate_option = "MANUAL_ONLY"
  nat_ips = [
    for ip in(
      length(try(each.value.ext_ip, [])) > 0
      ? each.value.ext_ip
      : sort(tolist(local.default_ips))
    ) : local.nat_ip_links[ip]
  ]

  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  dynamic "subnetwork" {
    for_each = each.value.network_config

    content {
      name = subnetwork.value.subnet
      source_ip_ranges_to_nat = length(try(subnetwork.value.ranges, [])) > 0 ? concat(try(subnetwork.value.primary, false) ? ["PRIMARY_IP_RANGE"] : [], ["LIST_OF_SECONDARY_IP_RANGES"]) : ["ALL_IP_RANGES"]      
      secondary_ip_range_names = length(try(subnetwork.value.ranges, [])) > 0 ? subnetwork.value.ranges : null 
    }
  }

  dynamic "rules" {
    for_each = try(each.value.rules, [])

    content {
      rule_number = rules.value.rule_number
      description = try(rules.value.description, each.key)

      match = try(
        rules.value.match,
        join(" || ", [
          for cidr in var.destination_ranges[rules.value.destination_ranges_source] :
          "inIpRange(destination.ip, '${cidr}')"
        ])
      )

      action {
        source_nat_active_ips = [
          for ip in rules.value.ext_ip :
          local.nat_ip_links[ip]
        ]
      }
    }
  }

  enable_endpoint_independent_mapping = false
}