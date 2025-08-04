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


resource "kubectl_manifest" "vault_certmanager" {
  yaml_body = templatefile("${path.module}/../../templates/cert-manager/ClusterIssuer.tftpl",{Values = local.vaultIssuer})
  depends_on = [
    # helm_release.vault,
    # vault_auth_backend.auth_kubernetes
  ]
}
