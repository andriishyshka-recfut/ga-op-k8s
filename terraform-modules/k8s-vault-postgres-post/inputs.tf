variable "Cluster" {}
variable "Color" {}
variable "Settings" {}
variable "GkeClusterConnectionSettings" {}
variable "VaultAddress" {}
variable "DbKind" { default = "postgres" }
variable "PostgresqlHaProfile" { default = null }
# false: Vault rotates the password immediately on import so it becomes the SOLE owner
# from t0. Must stay false while bootstrap only sets the password on initial CREATE (it no
# longer re-ALTERs it) — otherwise Vault never learns the password and static-creds serves
# a value that does not match the backend (pgpool pass-through -> backend auth failed).
variable "StaticRoleSkipImportRotation" { default = false }

data "vault_kv_secrets_list_v2" "db_user_list" {
  mount = "secret"
  name  = "${local.vault_path}/db-users"
}

data "vault_generic_secret" "databases" {
  for_each = local.databases
  path     = "secret/${local.vault_path}/db-users/${each.value}"
}

data "vault_generic_secret" "root_user" {
  path = "secret/${local.vault_path}/root-user"
}

locals {
  cluster_settings = var.Settings.clusters[var.Cluster]
  db_settings = (
    jsondecode(
      var.DbKind == "postgresql-ha"
      ? jsonencode(local.cluster_settings[var.DbKind][var.PostgresqlHaProfile])
      : jsonencode(local.cluster_settings[var.DbKind])
    )
  )

  vault_path                  = local.db_settings.vault_path
  vault_backend_path          = lookup(local.db_settings, "vault_backend_path", "postgres")
  postgres_ha_cluster_name    = var.DbKind == "postgresql-ha" ? local.db_settings.cluster_name : null
  postgres_uri                = var.DbKind == "postgresql-ha" ? "${local.postgres_ha_cluster_name}-pgpool.${local.db_settings.namespace}.svc.cluster.local:5432" : local.db_settings.postgres_uri
  credential_mode             = lookup(local.db_settings, "credential_mode", "dynamic")
  static_role_rotation_period = try(tonumber(lookup(local.db_settings, "static_role_rotation_period", 2592000)), 2592000)

  databases      = nonsensitive(toset(data.vault_kv_secrets_list_v2.db_user_list.names))
  database_names = sort(tolist(local.databases))
  db_user_pass   = { for name in local.database_names : name => tomap(data.vault_generic_secret.databases[name].data) }
  app_db_users = {
    for name in local.database_names : name => {
      rw_username = "${lookup(local.db_user_pass[name], "username", name)}-rw"
      ro_username = "${lookup(local.db_user_pass[name], "username", name)}-ro"
      rw_password = lookup(local.db_user_pass[name], "password", "")
      ro_password = lookup(local.db_user_pass[name], "password", "")
      rw_version  = parseint(substr(sha1(lookup(local.db_user_pass[name], "password", "")), 0, 8), 16)
      ro_version  = parseint(substr(sha1(lookup(local.db_user_pass[name], "password", "")), 0, 8), 16)
    }
  }
}
