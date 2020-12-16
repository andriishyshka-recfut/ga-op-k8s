
locals {
  minio-ns = "minio"
}
resource "kubernetes_namespace" "minio" {
  metadata {
    name = local.minio-ns
    # labels = {
    #   istio-injection = "enabled"
    # }
  }
}
resource "kubernetes_limit_range" "limit" {
  metadata {
    name      = "default-limit-range"
    namespace = local.minio-ns
  }
  spec {
    limit {
      type = "Container"
      default_request = {
        cpu    = "20m"
        memory = "50Mi"
      }
    }
  }
}

data "vault_generic_secret" "minio-credentials" {
  path = "secret/minio-credentials"
}

resource "kubernetes_secret" "minio-credentials" {
  metadata {
    name      = "minio-credentials"
    namespace = local.minio-ns
  }

  data = {
    "accesskey"    = data.vault_generic_secret.minio-credentials.data.accessKey
    "secretkey"    = data.vault_generic_secret.minio-credentials.data.secretKey
    "gcs_key.json" = base64decode(google_service_account_key.minio-key.private_key)
  }
  depends_on = [kubernetes_namespace.minio]

}

data "vault_generic_secret" "oidc_secrets" {
  path = "secret/oidc_google_test"
}

resource "helm_release" "minio" {
  name       = "minio"
  chart      = "minio"
  repository = "https://helm.min.io/"
  #version           = "0.1.0"
  namespace         = local.minio-ns
  dependency_update = "true"

  values = [
    templatefile("${path.root}/minio_values.tmpl",
      {
        CLIENT_ID          = data.vault_generic_secret.oidc_secrets.data.oidc_client_id
        OIDC_DISCOVERY_URL = data.vault_generic_secret.oidc_secrets.data.oidc_discovery_url
      }
    )
  ]
  depends_on = [
    kubernetes_namespace.minio,
    kubernetes_secret.minio-credentials,
    helm_release.etcd
  ]
}
