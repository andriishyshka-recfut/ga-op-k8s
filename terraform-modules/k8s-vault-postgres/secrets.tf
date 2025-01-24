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

resource "kubernetes_secret" "root" {
  metadata {
    name      = "${local.cluster_name}-superuser"
    namespace = local.namespace
  }
  data = {
    username = data.vault_generic_secret.root_user.data.username
    password = data.vault_generic_secret.root_user.data.password
  }
}
