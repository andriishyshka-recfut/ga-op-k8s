resource "zpa_app_connector_group" "group" {
  for_each = local.app_connector_groups

  name                    = each.key
  enabled                 = true
  city_country            = each.value.city_country
  country_code            = each.value.country_code
  latitude                = each.value.latitude
  longitude               = each.value.longitude
  location                = each.value.location
  upgrade_day             = "SUNDAY"
  dns_query_type          = "IPV4"
  lss_app_connector_group = true
}

resource "zpa_server_group" "group" {
  for_each = local.server_groups

  name              = each.key
  enabled           = true
  dynamic_discovery = true

  app_connector_groups {
    id = [zpa_app_connector_group.group[each.value.app_connector_group].id]
  }

  depends_on = [
    zpa_app_connector_group.group
  ]
}
