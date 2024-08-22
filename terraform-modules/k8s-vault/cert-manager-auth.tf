data "kubernetes_service_account" "cert_manager" {
  metadata {
    name      = "${var.Cluster}-cert-manager"
    namespace = "kube-system"
  }
  depends_on = [
    kubernetes_secret_v1.cert_manager
  ]
}

resource "kubernetes_secret_v1" "cert_manager" {
  metadata {
    namespace = "kube-system"
    name      = "sa-${var.Cluster}-cert-manager"
    annotations = {
      "kubernetes.io/service-account.name" = "${var.Cluster}-cert-manager"
    }
  }
  type = "kubernetes.io/service-account-token"
}

resource "helm_release" "vault_certmanager" {
  name      = "vault-issuer"
  chart     = "${path.module}/charts/vault_certmanager"
  namespace = "istio-ingress"
  wait      = true
  atomic    = true
  set {
    name  = "mountPath"
    value = "/v1/auth/k8s-${var.Cluster}-${var.Color}"
  }
  set {
    name  = "secretName"
    value = "sa-${var.Cluster}-cert-manager"
  }
  set {
    name  = "vaultAddress"
    value = var.VaultAddress
  }
  set {
    name  = "vaultRole"
    value = "cert-manager"
  }
  set {
    name  = "pkiRole"
    value = "elastic"
  }
  set {
    name  = "pkiPath"
    value = "pki-elastic-int"
  }
  depends_on = [
    helm_release.vault,
    vault_auth_backend.auth_kubernetes
  ]
}
