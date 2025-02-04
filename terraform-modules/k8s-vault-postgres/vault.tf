# resource "vault_mount" "db" {
#   path = "postgres"
#   type = "database"
# }

resource "vault_database_secret_backend_connection" "Connection" {
  for_each      = local.databases
  backend       = "postgres"
  name          = each.key
  allowed_roles = ["${each.key}-rw", "${each.key}-ro"]

  postgresql {
    connection_url = "postgres://{{username}}:{{password}}@${local.postgres_uri}/${each.key}"
    username       = data.vault_generic_secret.root_user.data.username
    password       = data.vault_generic_secret.root_user.data.password
  }
}

resource "vault_database_secret_backend_role" "Postgres_rw_role" {
  for_each        = local.databases
  backend         = "postgres"
  name            = "${each.key}-rw"
  db_name         = each.key
  default_ttl     = 2592000
  credential_type = "password"
  credential_config = {
    password_policy = "test"
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
  for_each        = local.databases
  backend         = "postgres"
  name            = "${each.key}-ro"
  db_name         = each.key
  default_ttl     = 2592000
  credential_type = "password"
  credential_config = {
    password_policy = "test"
  }
  creation_statements = [
    "CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}'; GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";"
  ]
  revocation_statements = [
    "REVOKE SELECT ON ALL TABLES IN SCHEMA public FROM \"{{name}}\"; DROP OWNED BY \"{{name}}\"; DROP ROLE \"{{name}}\";"
  ]
  depends_on = [vault_database_secret_backend_connection.Connection]
}
