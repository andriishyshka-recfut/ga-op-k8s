data "zpa_enrollment_cert" "connector" {
  name = local.provisioning_keys.enrollment_cert_name
}

resource "zpa_provisioning_key" "connector" {
  for_each = local.provisioning_keys.keys

  name               = each.value.name
  association_type   = each.value.association_type
  max_usage          = each.value.max_usage
  enrollment_cert_id = data.zpa_enrollment_cert.connector.id
  zcomponent_id      = zpa_app_connector_group.group[each.value.app_connector_group].id
  enabled            = true

  depends_on = [
    data.zpa_enrollment_cert.connector,
    zpa_app_connector_group.group
  ]
}

resource "vault_generic_secret" "server_keys" {
  path = local.provisioning_keys.vault_path

  data_json = jsonencode({
    for vault_key, key_config in local.provisioning_keys.keys :
    vault_key => zpa_provisioning_key.connector[vault_key].provisioning_key
  })

  depends_on = [zpa_provisioning_key.connector]
}
