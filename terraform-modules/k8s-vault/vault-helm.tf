
resource "helm_release" "vault" {
  name = "vault"
  #chart = "${path.module}/umbrella-vault"
  chart      = "vault"
  repository = "https://helm.releases.hashicorp.com"
  #version           = "0.1.0"
  namespace         = "vault"
  dependency_update = "true"
  values = [
    templatefile("${path.module}/vault_helm_config.tmpl",
      {
        project           = local.currentProject,
        key_ring          = local.vaultKeyName,
        crypto_key        = local.vaultKeyName,
        bucket            = local.vaultBucketName
        version           = var.Settings.clusters[var.Cluster][var.Color].vault.version
        replicas          = local.replicasCount
        externalVaultAddr = "https://${local.vaultFqdn}"
      }
    )
  ]

  depends_on = [
    kubernetes_secret.kms_creds,
    kubernetes_namespace.vault,

  ]
}

data "google_service_account" "vault_sa" {
  account_id = local.vaultServiceAccountId
}

resource "google_service_account_key" "vault_key" {
  service_account_id = data.google_service_account.vault_sa.name
}

resource "kubernetes_secret" "kms_creds" {
  metadata {
    name      = "kms-creds"
    namespace = "vault"
  }
  data = {
    "credentials.json" = base64decode(google_service_account_key.vault_key.private_key)
  }
  depends_on = [
    kubernetes_namespace.vault,

  ]
}

resource "kubernetes_namespace" "vault" {
  metadata {
    name = "vault"
    labels = {
      istio-injection = "enabled"
    }
  }
}
