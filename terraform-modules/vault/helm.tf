
resource "helm_release" "vault" {
  name  = "vault"
  chart = "${path.module}/umbrella-vault"

  version           = "0.1.0"
  namespace         = "vault"
  dependency_update = "true"

  values = [
    templatefile("${path.module}/helm_config.tmpl",
      {
        project    = data.google_project.vault.project_id,
        key_ring   = var.autounseal_kms_key_ring_name,
        crypto_key = var.autounseal_kms_crypto_key_name,
        bucket     = var.bucket_name,
        version    = var.vault-version
        subdomain  = "${var.cluster}.${var.settings.cluster_settings[var.cluster].domain}"
      }
    )
  ]


  depends_on = [
    kubernetes_secret.kms-creds,
    kubernetes_namespace.vault,
    google_service_account.vault-server,
    var.gke_cluster_endpoint

  ]
}



resource "kubernetes_secret" "kms-creds" {
  metadata {
    name      = "kms-creds"
    namespace = "vault"
  }
  data = {
    "credentials.json" = base64decode(google_service_account_key.vault-key.private_key)
  }
}

resource "kubernetes_namespace" "vault" {
  metadata {
    name = "vault"
    labels = {
      istio-injection = "enabled"
    }
  }
  depends_on = [
    var.gke_cluster_endpoint
  ]
}
