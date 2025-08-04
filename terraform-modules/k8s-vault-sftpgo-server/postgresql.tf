resource "helm_release" "postgresql" {
  for_each     = var.Cluster == "production" ? {} : var.server_list 
  name         = "postgresql-sftpgo-${each.key}"
  repository   = "oci://registry-1.docker.io/bitnamicharts"
  chart        = "postgresql"
  wait         = true
  atomic       = true
  namespace    = try(each.value.namespace, local.namespace)
  version      = local.postgresql_chart_version
  reset_values = true
  set = [
    {
      name  = "nameOverride"
      value = "postgresql"
    },
    {
      name  = "global.postgresql.auth.username"
      value = data.vault_generic_secret.db_creds["${each.key}"].data["username"]
    },
    {
      name  = "global.postgresql.auth.password"
      value = data.vault_generic_secret.db_creds["${each.key}"].data["password"]
    },
    {
      name  = "global.postgresql.auth.database"
      value = data.vault_generic_secret.db_creds["${each.key}"].data["db_name"]
    },
    {
      name  = "global.postgresql.auth.postgresPassword"
      value = data.vault_generic_secret.db_creds["${each.key}"].data["postgres_password"]
    },
    {
      name  = "image.tag"
      value = local.postgresql_version
    }
  ]
}