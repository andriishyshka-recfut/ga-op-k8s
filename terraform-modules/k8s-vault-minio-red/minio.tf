
data "vault_generic_secret" "root_credentials_from_vault" {
  path = local.vaultRootCredentialsPath
}
data "vault_generic_secret" "minio_sa" {
  path = "secret/sa/minio"
}

data "vault_generic_secret" "oidc_secrets" {
  path = local.vaultOidcConfigPath
}


resource "kubernetes_secret" "minio_credentials_kubernetes_secret" {
  metadata {
    name      = "minio-cluster"
    namespace = local.minioNs
  }

  data = {
    "config.env" = join("\n",
      [
        "export MINIO_ROOT_USER=${data.vault_generic_secret.root_credentials_from_vault.data.accessKey}",
        "export MINIO_ROOT_PASSWORD=${data.vault_generic_secret.root_credentials_from_vault.data.secretKey}"
      ]
    )

  }
}


resource "helm_release" "minio_operator" {
  name       = "minio-operator"
  chart      = "operator"
  repository = "https://operator.min.io/"
  namespace  = "minio-operator"
  # atomic            = "true"
  dependency_update = "true"
  values = [
    file("${path.module}/operator_values.yaml")
  ]
  timeout    = 120
  depends_on = [kubernetes_persistent_volume_claim.minio_tenant_pvc]
}

resource "helm_release" "minio_tenant" {
  name       = "minio-tenant"
  chart      = "tenant"
  repository = "https://operator.min.io/"
  namespace  = local.minioNs
  # atomic            = "true"
  dependency_update = "true"
  values = [
    templatefile("${path.module}/templates/tenant.tftpl", { values = local.minioSettings })
  ]
  depends_on = [
    helm_release.minio_operator,
    kubernetes_secret.minio_credentials_kubernetes_secret,
    kubectl_manifest.certificate_vault_minio
  ]
}
