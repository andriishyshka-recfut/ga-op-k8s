
data "vault_generic_secret" "minio_default_settings" {
  path = "secret/etl/minio"
}

data "vault_generic_secret" "gcp_sa_keys" {
  path = "secret/etl/google_credentials"
}

data "vault_generic_secret" "api_keys" {
  path = "secret/etl/vault"
}



resource "kubernetes_secret" "minio_default_settings" {
  metadata {
    name      = "minio-default-settings"
    namespace = local.namespace
  }

  data = {
    "endpoint" = data.vault_generic_secret.minio_default_settings.data.ENDPOINT
    "minio-bucket"    = data.vault_generic_secret.minio_default_settings.data.MINIO_BUCKET
  }
}


resource "kubernetes_secret" "api_keys" {
  metadata {
    name      = "api-keys"
    namespace = local.namespace
  }

  data = {
    "vault" = jsonencode(data.vault_generic_secret.api_keys.data)
  }
  
}



resource "kubernetes_secret" "google_credentials" {
  metadata {
    name      = "google-sa-credentials"
    namespace = local.namespace
  }

  data = {
    "cppfeed" = data.vault_generic_secret.gcp_sa_keys.data.cppfeed
  }
}


resource "kubernetes_manifest" "externalsecret_ssh" {
  manifest = {
    "apiVersion" = "external-secrets.io/v1beta1"
    "kind"       = "ExternalSecret"
    "metadata" = {
      "name" = "ssh"
      "namespace" : local.namespace
    }
    "spec" = {
      "target" = {
        "name" = "ssh"
      }
      "dataFrom" = [
        {
          "extract" = {
            "key" = "secret/data/etl/ssh"
          }
        },
      ]
      "refreshInterval" = "1m"
      "secretStoreRef" = {
        "kind" = "SecretStore"
        "name" = "vault-backend"
      }
    }
  }
  depends_on = [helm_release.etl_operator]

}
