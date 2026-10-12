resource "vault_database_secret_backend_connection" "Connection" {
  for_each      = toset(local.database_names)
  backend       = local.vault_backend_path
  name          = each.key
  allowed_roles = ["${each.key}-rw", "${each.key}-ro"]

  postgresql {
    connection_url          = "postgres://{{username}}:{{password}}@${local.postgres_uri}/${each.key}"
    username                = data.vault_generic_secret.root_user.data.username
    password                = data.vault_generic_secret.root_user.data.password
    password_authentication = "scram-sha-256"
  }
}

resource "vault_database_secret_backend_role" "Postgres_rw_role" {
  for_each        = local.credential_mode == "dynamic" ? toset(local.database_names) : toset([])
  backend         = local.vault_backend_path
  name            = "${each.key}-rw"
  db_name         = each.key
  default_ttl     = 2592000
  credential_type = "password"
  credential_config = {
    password_policy = "main32"
  }
  creation_statements = [
    "CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}'; GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO \"{{name}}\";"
  ]
  revocation_statements = [
    "REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM \"{{name}}\"; DROP OWNED BY \"{{name}}\"; DROP ROLE \"{{name}}\";"
  ]
  depends_on = [vault_database_secret_backend_connection.Connection]
}

resource "vault_database_secret_backend_role" "Postgres_ro_role" {
  for_each        = local.credential_mode == "dynamic" ? toset(local.database_names) : toset([])
  backend         = local.vault_backend_path
  name            = "${each.key}-ro"
  db_name         = each.key
  default_ttl     = 2592000
  credential_type = "password"
  credential_config = {
    password_policy = "main32"
  }
  creation_statements = [
    "CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}'; GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";"
  ]
  revocation_statements = [
    "REVOKE SELECT ON ALL TABLES IN SCHEMA public FROM \"{{name}}\"; DROP OWNED BY \"{{name}}\"; DROP ROLE \"{{name}}\";"
  ]
  depends_on = [vault_database_secret_backend_connection.Connection]
}

resource "vault_database_secret_backend_static_role" "Postgres_static_rw_role" {
  for_each             = local.credential_mode == "static" ? toset(local.database_names) : toset([])
  backend              = local.vault_backend_path
  name                 = "${each.key}-rw"
  db_name              = each.key
  username             = local.app_db_users[each.key].rw_username
  password_wo          = local.app_db_users[each.key].rw_password
  password_wo_version  = local.app_db_users[each.key].rw_version
  skip_import_rotation = var.StaticRoleSkipImportRotation
  credential_type      = "password"
  credential_config = {
    password_policy = "main32"
  }
  rotation_period = local.static_role_rotation_period

  depends_on = [vault_database_secret_backend_connection.Connection]
}

resource "vault_database_secret_backend_static_role" "Postgres_static_ro_role" {
  for_each = local.credential_mode == "static" ? toset(local.database_names) : toset([])

  backend              = local.vault_backend_path
  name                 = "${each.key}-ro"
  db_name              = each.key
  username             = local.app_db_users[each.key].ro_username
  password_wo          = local.app_db_users[each.key].ro_password
  password_wo_version  = local.app_db_users[each.key].ro_version
  skip_import_rotation = var.StaticRoleSkipImportRotation
  credential_type      = "password"
  credential_config = {
    password_policy = "main32"
  }
  rotation_period = local.static_role_rotation_period

  depends_on = [vault_database_secret_backend_connection.Connection]
}
