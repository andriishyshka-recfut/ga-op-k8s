
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
        project    = var.vault_resources.project,
        key_ring   = var.vault_resources.key_ring,
        crypto_key = var.vault_resources.crypto_key,
        bucket     = var.vault_resources.bucket
        version    = var.settings[var.cluster].vault.version
      }
    )
  ]


  depends_on = [
    kubernetes_secret.kms-creds,
    kubernetes_namespace.vault,
    var.gke_cluster_endpoint

  ]
}



resource "kubernetes_secret" "kms-creds" {
  metadata {
    name      = "kms-creds"
    namespace = "vault"
  }
  data = {
    "credentials.json" = var.vault_resources.vault_sa_priv_key
  }
  depends_on = [
    kubernetes_namespace.vault,
    var.node_pool,
    var.gke_cluster_endpoint

  ]
}

resource "kubernetes_namespace" "vault" {
  metadata {
    name = "vault"
    labels = {
      istio-injection = "enabled"
    }
  }
  depends_on = [
    var.gke_cluster_endpoint,
    var.node_pool,
  ]
}
