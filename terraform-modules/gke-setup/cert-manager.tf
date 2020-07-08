resource "helm_release" "cert-manager" {
  name       = "${var.cluster}-cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = var.settings.cluster_settings[var.cluster].cert_manager_version
  namespace  = "kube-system"
  set {
    name  = "installCRDs"
    value = "true"
  }

  // Configure cert-manager to cleanup secrets on delete
  // https://github.com/jetstack/cert-manager/pull/819
  set {
    name  = "extraArgs[0]"
    value = "--enable-certificate-owner-ref=true"
  }
  depends_on = [
    google_container_node_pool.cluster_preemptible_nodes
  ]
}
