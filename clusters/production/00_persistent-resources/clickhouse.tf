locals {
  clickhouse_settings        = var.Settings.clusters[var.Cluster].clickhouse
  enable_clickhouse          = local.clickhouse_settings.enabled
  clickhouse_vault_auth_path = "mw/clickhouse/auth"
}

ephemeral "random_password" "clickhouse_default" {
  count = local.enable_clickhouse ? 1 : 0

  length  = 32
  special = false
}

resource "vault_kv_secret_v2" "clickhouse_default" {
  count = local.enable_clickhouse ? 1 : 0

  mount = "secret"
  name  = local.clickhouse_vault_auth_path

  data_json_wo = jsonencode({
    username = "default"
    password = ephemeral.random_password.clickhouse_default[0].result
  })
  data_json_wo_version = 1
}

ephemeral "random_password" "clickhouse_cluster" {
  for_each = local.enable_clickhouse ? toset([
    "interserver-password", "management-password", "keeper-identity", "cluster-secret",
  ]) : toset([])

  length  = 32
  special = false
}

ephemeral "random_bytes" "clickhouse_named_collections" {
  count  = local.enable_clickhouse ? 1 : 0
  length = 16
}

resource "vault_kv_secret_v2" "clickhouse_cluster" {
  count = local.enable_clickhouse ? 1 : 0

  mount = "secret"
  name  = "mw/clickhouse/cluster"

  data_json_wo = jsonencode(merge({
    for key, password in ephemeral.random_password.clickhouse_cluster :
    key => key == "keeper-identity" ? "clickhouse:${password.result}" : password.result
    }, {
    "named-collections-key" = ephemeral.random_bytes.clickhouse_named_collections[0].hex
  }))
  data_json_wo_version = 1
}
