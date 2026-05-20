locals {
  postgres_vault_path    = var.Settings.clusters[var.Cluster].postgres.vault_path
  postgres_ha_vault_path = try(var.Settings.clusters[var.Cluster]["postgresql-ha"].vault_path, local.postgres_vault_path)
}

resource "random_password" "postgres_root" {
  length  = 32
  special = false
}

resource "random_password" "postgresql_ha_repmgr" {
  length  = 32
  special = false
}

resource "random_password" "postgresql_ha_pgpool_admin" {
  length  = 32
  special = false
}

resource "vault_generic_secret" "postgres_root" {
  path = "secret/${local.postgres_vault_path}/root-user"

  data_json = jsonencode(
    {
      username = "postgres",
      password = random_password.postgres_root.result
    }
  )
  depends_on = [random_password.postgres_root]
}

resource "vault_generic_secret" "postgresql_ha_auth" {
  path = "secret/${local.postgres_ha_vault_path}/ha-auth"

  data_json = jsonencode(
    {
      repmgr_username   = "repmgr"
      repmgr_password   = random_password.postgresql_ha_repmgr.result
      sr_check_username = "repmgr"
      sr_check_password = random_password.postgresql_ha_repmgr.result
      admin_username    = "admin"
      admin_password    = random_password.postgresql_ha_pgpool_admin.result
    }
  )

  depends_on = [
    random_password.postgresql_ha_repmgr,
    random_password.postgresql_ha_pgpool_admin,
  ]
}

resource "vault_mount" "postgres" {
  path = "postgres"
  type = "database"
}

resource "vault_database_secret_backend_connection" "postgres" {
  backend           = vault_mount.postgres.path
  name              = "postgres"
  plugin_name       = "postgresql-database-plugin"
  verify_connection = false

  postgresql {
    connection_url = "postgres://postgres:${random_password.postgres_root.result}@postgres-rw.postgres:5432/postgres"
  }
  depends_on = [
    vault_generic_secret.postgres_root,
    vault_mount.postgres
  ]
}

