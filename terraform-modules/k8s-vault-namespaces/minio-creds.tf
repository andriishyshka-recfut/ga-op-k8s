
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
    "accesskey" = data.vault_generic_secret.users_credentials_from_vault[each.key].data.ACCESS_KEY_ID
    "secretkey" = data.vault_generic_secret.users_credentials_from_vault[each.key].data.SECRET_ACCESS_KEY
    "ca.crt"    = data.vault_generic_secret.users_credentials_from_vault[each.key].data.CA_CRT
  }
  depends_on = [
    kubernetes_namespace.ns
  ]

}
