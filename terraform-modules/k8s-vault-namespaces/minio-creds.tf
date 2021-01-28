
data "vault_generic_secret" "users_credentials_from_vault" {
  path = local.vaultUsersCredentialsPath
}

resource "kubernetes_secret" "minio_credentials_kubernetes_secret" {
  for_each = local.minioCreds
  metadata {
    name      = "minio-credentials"
    namespace = each.key
  }

  data = {
    "accesskey" = jsondecode(data.vault_generic_secret.users_credentials_from_vault.data[each.value[0]]).accessKey
    "secretkey" = jsondecode(data.vault_generic_secret.users_credentials_from_vault.data[each.value[0]]).secretKey
  }

}
