data "vault_generic_secret" "minio_ca" {
  path = "pki-minio/cert/ca"
}

resource "kubernetes_secret" "minio_ca" {
  metadata {
    name      = "minio-ca"
    namespace = local.namespace
  }

  data = {
    "ca.crt" = data.vault_generic_secret.minio_ca.data["certificate"]
  }
}
