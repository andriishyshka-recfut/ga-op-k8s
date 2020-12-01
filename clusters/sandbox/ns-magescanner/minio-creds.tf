
data "vault_generic_secret" "minio_creds" {
  path = "secret/minio-credentials"
}


resource "kubernetes_secret" "minio-credentials" {
  metadata {
    name      = "minio-credentials"
    namespace = local.ns
  }

  data = {
    "accesskey" = data.vault_generic_secret.minio_creds.data.magescannerAccessKey
    "secretkey" = data.vault_generic_secret.minio_creds.data.magescannerSecretKey
  }
  depends_on = [kubernetes_namespace.ns]

}
