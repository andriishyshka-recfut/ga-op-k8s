locals {
  postgres_settings    = try(var.Settings.clusters[var.Cluster].postgres, {})
  postgres_ha_profiles = try(var.Settings.clusters[var.Cluster]["postgresql-ha"], {})
  enabled_postgres_ha_profiles = {
    for name, cfg in local.postgres_ha_profiles : name => cfg
    if lookup(cfg, "enabled", false)
  }
  postgres_ha_connection_uris = {
    for name, cfg in local.enabled_postgres_ha_profiles :
    name => format(
      "%s-pgpool.%s.svc.cluster.local:5432",
      cfg.cluster_name,
      cfg.namespace
    )
  }

  enable_postgres = lookup(local.postgres_settings, "enabled", false)

  postgres_vault_path   = try(local.postgres_settings.vault_path, null)
  postgres_backend_path = lookup(local.postgres_settings, "vault_backend_path", "postgres")
  postgres_uri          = try(local.postgres_settings.postgres_uri, null)
}

resource "random_password" "postgres_root" {
  count   = local.enable_postgres ? 1 : 0
  length  = 32
  special = false
}

resource "random_password" "postgresql_ha_root" {
  for_each = local.enabled_postgres_ha_profiles

  length  = 32
  special = false
}

resource "random_password" "postgresql_ha_repmgr" {
  for_each = local.enabled_postgres_ha_profiles

  length  = 32
  special = false
}

resource "random_password" "postgresql_ha_pgpool_admin" {
  for_each = local.enabled_postgres_ha_profiles

  length  = 32
  special = false
}

resource "vault_generic_secret" "postgres_root" {
  count = local.enable_postgres ? 1 : 0
  path  = "secret/${local.postgres_vault_path}/root-user"

  data_json = jsonencode(
    {
      username = "postgres",
      password = random_password.postgres_root[0].result
    }
  )
  depends_on = [random_password.postgres_root]
}

resource "vault_generic_secret" "postgresql_ha_root" {
  for_each = local.enabled_postgres_ha_profiles
  path     = "secret/${each.value.vault_path}/root-user"

  data_json = jsonencode(
    {
      username = "postgres"
      password = random_password.postgresql_ha_root[each.key].result
    }
  )

  depends_on = [
    random_password.postgresql_ha_root,
  ]
}

resource "vault_generic_secret" "postgresql_ha_auth" {
  for_each = local.enabled_postgres_ha_profiles
  path     = "secret/${lookup(each.value, "ha_auth_vault_path", "${each.value.vault_path}/ha-auth")}"

  data_json = jsonencode(
    {
      repmgr_username   = "repmgr"
      repmgr_password   = random_password.postgresql_ha_repmgr[each.key].result
      sr_check_username = "repmgr"
      sr_check_password = random_password.postgresql_ha_repmgr[each.key].result
      admin_username    = "admin"
      admin_password    = random_password.postgresql_ha_pgpool_admin[each.key].result
    }
  )

  depends_on = [
    random_password.postgresql_ha_repmgr,
    random_password.postgresql_ha_pgpool_admin,
  ]
}

resource "vault_mount" "postgres" {
  count = local.enable_postgres ? 1 : 0
  path  = local.postgres_backend_path
  type  = "database"
}

resource "vault_database_secret_backend_connection" "postgres" {
  count             = local.enable_postgres ? 1 : 0
  backend           = vault_mount.postgres[0].path
  name              = local.postgres_backend_path
  plugin_name       = "postgresql-database-plugin"
  verify_connection = false

  postgresql {
    connection_url = "postgres://postgres:${random_password.postgres_root[0].result}@${local.postgres_uri}/postgres"
  }
  depends_on = [
    vault_generic_secret.postgres_root,
    vault_mount.postgres
  ]
}

resource "vault_mount" "postgres_ha" {
  for_each = local.enabled_postgres_ha_profiles
  path     = lookup(each.value, "vault_backend_path", "postgres-ha")
  type     = "database"
}

resource "vault_database_secret_backend_connection" "postgres_ha" {
  for_each          = local.enabled_postgres_ha_profiles
  backend           = vault_mount.postgres_ha[each.key].path
  name              = lookup(each.value, "vault_backend_path", "postgres-ha")
  plugin_name       = "postgresql-database-plugin"
  verify_connection = false

  postgresql {
    connection_url = "postgres://postgres:${random_password.postgresql_ha_root[each.key].result}@${local.postgres_ha_connection_uris[each.key]}/postgres"
  }

  depends_on = [
    vault_generic_secret.postgresql_ha_root,
    vault_mount.postgres_ha,
  ]
}
