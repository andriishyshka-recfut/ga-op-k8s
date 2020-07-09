
resource "helm_release" "vault" {
  name = "vault"
  #chart = "${path.module}/umbrella-vault"
  chart      = "vault"
  repository = "https://helm.releases.hashicorp.com"
  #version           = "0.1.0"
  namespace         = "vault"
  dependency_update = "true"

  values = [
    templatefile("${path.module}/helm_config.tmpl",
      {
        project    = data.google_project.vault.project_id,
        key_ring   = google_kms_key_ring.vault.name,
        crypto_key = google_kms_crypto_key.vault-init.name,
        bucket     = google_storage_bucket.vault.name
        version    = var.settings.cluster_settings[var.cluster].vault.version
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
