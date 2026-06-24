resource "zpa_segment_group" "group" {
  for_each = local.segment_groups

  name    = each.key
  enabled = true

  depends_on = [zpa_server_group.group]
}

resource "zpa_application_segment" "segment" {
  for_each = local.application_segments

  name              = each.value.name
  enabled           = true
  health_reporting  = "ON_ACCESS"
  bypass_type       = "NEVER"
  is_cname_enabled  = true
  domain_names      = each.value.domain_names
  segment_group_id  = zpa_segment_group.group[each.value.segment_group].id
  tcp_port_range    = each.value.tcp_port_range
  udp_port_range    = each.value.udp_port_range

  server_groups {
    id = [zpa_server_group.group[each.value.server_group].id]
  }

  depends_on = [
    zpa_segment_group.group,
    zpa_server_group.group
  ]
}
