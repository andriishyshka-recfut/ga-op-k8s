resource "helm_release" "vault" {
  name       = "vault"
  repository = "https://helm.releases.hashicorp.com"
  chart      = "vault"
  version    = "0.5.0"
  namespace = "vault"

  values = [
    templatefile("${path.module}/helm_config.tmpl" ,
      {
        project = data.google_project.vault.project_id ,
        key_ring = google_kms_key_ring.vault.name ,
        crypto_key = google_kms_crypto_key.vault-init.name ,
        bucket = google_storage_bucket.vault.name
      }
    )
  ]

  set {
    name  = "server.ha.enabled"
    value = "true"
  }


  depends_on = [
    kubernetes_secret.kms-creds,
    kubernetes_namespace.vault,
    google_service_account.vault-server

  ]
}

resource "kubernetes_secret" "kms-creds" {
  metadata {
    name = "kms-creds"
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
}
