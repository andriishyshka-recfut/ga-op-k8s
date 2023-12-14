
data "vault_generic_secret" "root_credentials_from_vault" {
  path = local.vaultRootCredentialsPath
}
data "vault_generic_secret" "minio_sa" {
  path = "secret/sa/minio"
}

resource "kubernetes_secret" "minio_credentials_kubernetes_secret" {
  metadata {
    name      = "minio-credentials"
    namespace = local.minioNs
  }

  data = {
    "accesskey"    = data.vault_generic_secret.root_credentials_from_vault.data.accessKey
    "secretkey"    = data.vault_generic_secret.root_credentials_from_vault.data.secretKey
    "gcs_key.json" = base64decode(data.vault_generic_secret.minio_sa.data.gcs_key)
  }

}

data "vault_generic_secret" "oidc_secrets" {
  path = local.vaultOidcConfigPath
}

resource "helm_release" "minio" {
  name              = "minio"
  chart             = "minio"
  repository        = "oci://harbor.regemini.io/helm"
  version           = "8.0.10"
  namespace         = local.minioNs
  dependency_update = "true"
  timeout           = 120

  values = [
    file("${path.module}/minio_values.yaml")
  ]
  set {
    name  = "gcsgateway.replicas"
    value = local.replicas
  }
  set {
    name  = "podAnnotations.sidecar\\.istio\\.io/inject"
    value = " False"
  }
  set {
    name  = "environment.MINIO_IDENTITY_OPENID_CLIENT_ID"
    value = data.vault_generic_secret.oidc_secrets.data.oidc_client_id
  }
  set {
    name  = "environment.MINIO_IDENTITY_OPENID_CONFIG_URL"
    value = "${data.vault_generic_secret.oidc_secrets.data.oidc_discovery_url}/.well-known/openid-configuration"
  }
  set {
    name  = "environment.MINIO_DOMAIN"
    value = local.minioFqdn
  }
  set {
    name  = "environment.MINIO_BROWSER_REDIRECT_URL"
    value = local.minioConsoleFqdn
  }
  set {
    name  = "gcsgateway.projectId"
    value = local.currentProject
  }
  set {
    name  = "image.tag"
    value = local.imageTag
  }

  depends_on = [
    kubernetes_secret.minio_credentials_kubernetes_secret,
    helm_release.etcd
  ]
}
