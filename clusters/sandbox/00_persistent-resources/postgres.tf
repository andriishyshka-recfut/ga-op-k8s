resource "random_password" "postgres_root" {
  length  = 32
  special = false
}


resource "vault_generic_secret" "postgres_root" {
  path = "secret/${var.Settings.clusters[var.Cluster].postgres.vault_path}/root-user"

  data_json = jsonencode(
    {
      username = "postgres",
      password = random_password.postgres_root.result
    }
  )
  depends_on = [random_password.postgres_root]
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


