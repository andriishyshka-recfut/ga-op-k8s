
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
      "MINIO_ROOT_USER=${data.vault_generic_secret.root_credentials_from_vault.data.accessKey}",
      "MINIO_ROOT_PASSWORD=${data.vault_generic_secret.root_credentials_from_vault.data.secretKey}"
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
  timeout = 120
  depends_on = [   kubernetes_persistent_volume_claim.minio_tenant_pvc ]
}

resource "helm_release" "minio_tenant" {
  name       = "minio-tenant"
  chart      = "tenant"
  repository = "https://operator.min.io/"
  namespace  = local.minioNs
  # atomic            = "true"
  dependency_update = "true"
  values = [
    file("${path.module}/tenant_values.yaml")
  ]

  set {
    name  = "tenant.env[5].name"
    value = "MINIO_IDENTITY_OPENID_CLIENT_ID"
  }
  set_sensitive {
    name  = "tenant.env[5].value"
    value = data.vault_generic_secret.oidc_secrets.data.oidc_client_id
  }
  set {
    name = "tenant.env[6].name"
    value = "MINIO_IDENTITY_OPENID_CONFIG_URL"
  }
  set {
    name = "tenant.env[6].value"
    value = "${data.vault_generic_secret.oidc_secrets.data.oidc_discovery_url}/.well-known/openid-configuration"
  }
  set {
    name = "tenant.env[7].name"
    value = "MINIO_IDENTITY_OPENID_CLIENT_SECRET"
  }
  set_sensitive {
    name = "tenant.env[7].value"
    value = data.vault_generic_secret.oidc_secrets.data.oidc_client_secret
  }
  set_sensitive {
    name = "tenant.env[8].name"
    value = "MINIO_BROWSER_REDIRECT_URL"
  }
  set_sensitive {
    name = "tenant.env[8].value"
    value = "https://${local.minioFqdn}"
  }

  # timeout           = 120
  depends_on = [helm_release.minio_operator, 
  kubernetes_secret.minio_credentials_kubernetes_secret, 
  kubernetes_manifest.certificate_minio_helm_vault_minio]
}
