resource "kubernetes_role" "cert_manager_token_request" {
  metadata {
    name      = "cert-manager-token-request"
    namespace = local.globalSettings.namespace
  }

  rule {
    api_groups = [""]
    resources  = ["serviceaccounts/token"]
    verbs      = ["create"]
  }
}

resource "kubernetes_role_binding" "cert_manager_token_request" {
  metadata {
    name      = "cert-manager-token-request"
    namespace = local.globalSettings.namespace
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.cert_manager_token_request.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = "${var.Cluster}-cert-manager"
    namespace = "kube-system"
  }
}
