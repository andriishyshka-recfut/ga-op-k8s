data "vault_generic_secret" "backup_minio_auth" {
  count = local.backup_enabled ? 1 : 0
  path  = local.backup_minio_vault_path
}

resource "kubernetes_secret_v1" "backup_minio" {
  count = local.backup_enabled ? 1 : 0

  metadata {
    name      = local.backup_secret_name
    namespace = local.namespace
  }

  data = {
    access_key = jsondecode(data.vault_generic_secret.backup_minio_auth[0].data[local.backup_minio_user]).accessKey
    secret_key = jsondecode(data.vault_generic_secret.backup_minio_auth[0].data[local.backup_minio_user]).secretKey
  }
}
