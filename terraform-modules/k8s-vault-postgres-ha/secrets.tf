resource "kubernetes_secret" "postgresql_ha_auth" {
  metadata {
    name      = local.auth_secret_name
    namespace = local.namespace
  }

  # Bitnami postgresql-ha expects these exact keys for existingSecret.
  data = {
    "password"          = data.vault_generic_secret.root_user.data.password
    "postgres-password" = data.vault_generic_secret.root_user.data.password
    "repmgr-password"   = data.vault_generic_secret.ha_auth.data.repmgr_password
    "sr-check-password" = data.vault_generic_secret.ha_auth.data.sr_check_password
    "admin-password"    = data.vault_generic_secret.ha_auth.data.admin_password
  }
}

resource "kubernetes_secret" "root" {
  metadata {
    name      = local.root_secret_name
    namespace = local.namespace
  }

  data = {
    username = data.vault_generic_secret.root_user.data.username
    password = data.vault_generic_secret.root_user.data.password
  }
}

resource "kubernetes_secret" "db_users" {
  for_each = local.db_user_pass

  metadata {
    name      = "${local.cluster_name}-user-${each.key}"
    namespace = local.namespace
  }

  data = {
    username = each.value.username
    password = each.value.password
  }
}

resource "kubernetes_secret" "pgpool_custom_users" {
  count = length(local.db_user_names) > 0 ? 1 : 0

  metadata {
    name      = local.pgpool_custom_users_secret_name
    namespace = local.namespace
  }

  data = {
    usernames = local.pgpool_custom_usernames
    passwords = local.pgpool_custom_passwords
  }
}

resource "kubernetes_secret" "db_bootstrap_sql" {
  count = local.enable_db_bootstrap && length(local.db_user_pass) > 0 ? 1 : 0

  metadata {
    name      = local.db_bootstrap_secret_name
    namespace = local.namespace
  }

  data = {
    "bootstrap.sql" = local.db_bootstrap_sql
  }
}
