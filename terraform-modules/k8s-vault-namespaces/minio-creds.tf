
data "vault_generic_secret" "users_credentials_from_vault" {
  for_each = local.minioCreds
  path = "${local.vaultUsersCredentialsPath}/${each.value}"
}

resource "kubernetes_secret" "minio_credentials_kubernetes_secret" {
  for_each = local.minioCreds
  metadata {
    name      = "minio-credentials"
    namespace = each.key
  }

  data = {
    "accesskey" = data.vault_generic_secret.users_credentials_from_vault[each.key].data.access_key
    "secretkey" = data.vault_generic_secret.users_credentials_from_vault[each.key].data.secret_key
  }
  depends_on = [
    kubernetes_namespace.ns
  ]

}
