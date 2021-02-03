data "vault_generic_secret" "minio_creds" {
  path = "secret/minio/users"
}
locals {
  accessKey = jsondecode(data.vault_generic_secret.minio_creds.data["backup"]).accessKey
  secretKey = jsondecode(data.vault_generic_secret.minio_creds.data["backup"]).secretKey
}
resource "kubernetes_secret" "minio_credentials" {
  metadata {
    name      = "minio-credentials"
    namespace = local.esValues.namespace
  }
  data = {
    "s3.client.default.access_key" = local.accessKey
    "s3.client.default.secret_key" = local.secretKey
  }
}
