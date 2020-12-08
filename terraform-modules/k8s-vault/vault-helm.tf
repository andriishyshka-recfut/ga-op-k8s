
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
        project    = local.project,
        key_ring   = local.vault_key_name,
        crypto_key = local.vault_key_name,
        bucket     = local.vault_bucket_name
        version    = var.settings.clusters[var.cluster][var.color].vault.version
      }
    )
  ]

  depends_on = [
    kubernetes_secret.kms-creds,
    kubernetes_namespace.vault,

  ]
}

data "google_service_account" "vault-sa" {
  account_id = local.vault_service_account_id
}

resource "google_service_account_key" "vault-key" {
  service_account_id = data.google_service_account.vault-sa.name
}

resource "kubernetes_secret" "kms-creds" {
  metadata {
    name      = "kms-creds"
    namespace = "vault"
  }
  data = {
    "credentials.json" = base64decode(google_service_account_key.vault-key.private_key)
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
