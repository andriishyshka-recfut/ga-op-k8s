
data "vault_generic_secret" "root_credentials_from_vault" {
  path = local.vaultRootCredentialsPath
}

data "google_service_account" "minio_sa" {
  account_id = local.minioServiceAccountId
}

resource "google_service_account_key" "minio_key" {
  service_account_id = data.google_service_account.minio_sa.name
}

resource "kubernetes_secret" "minio_credentials_kubernetes_secret" {
  metadata {
    name      = "minio-credentials"
    namespace = local.minioNs
  }

  data = {
    "accesskey"    = data.vault_generic_secret.root_credentials_from_vault.data.accessKey
    "secretkey"    = data.vault_generic_secret.root_credentials_from_vault.data.secretKey
    "gcs_key.json" = base64decode(google_service_account_key.minio_key.private_key)
  }

}

data "vault_generic_secret" "oidc_secrets" {
  path = "secret/oidc_google_test"
}

resource "helm_release" "minio" {
  name       = "minio"
  chart      = "minio"
  repository = "https://helm.min.io/"
  #version           = "0.1.0"
  namespace         = local.minioNs
  dependency_update = "true"

  values = [
    templatefile("${path.module}/minio_values.tmpl",
      {
        CLIENT_ID          = data.vault_generic_secret.oidc_secrets.data.oidc_client_id
        OIDC_DISCOVERY_URL = data.vault_generic_secret.oidc_secrets.data.oidc_discovery_url
      }
    )
  ]
  depends_on = [
    kubernetes_secret.minio_credentials_kubernetes_secret,
    helm_release.etcd
  ]
}
