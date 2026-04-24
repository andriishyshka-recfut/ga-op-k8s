resource "kubernetes_service_account_v1" "bastion" {
  metadata {
    name      = "bastion"
    namespace = "kube-system"
  }
}
resource "kubernetes_cluster_role" "node_list" {
  metadata {
    name = "node-list"
  }

  rule {
    api_groups = [""]
    resources  = ["nodes"]
    verbs      = ["list"]
  }
}

resource "kubernetes_cluster_role_binding" "bastion_access" {
  metadata {
    name = "bastion-access"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "node-list"
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.bastion.metadata[0].name
    namespace = "kube-system"
  }
  depends_on = [
    kubernetes_cluster_role.node_list,
    kubernetes_service_account_v1.bastion
  ]
}

resource "kubernetes_secret_v1" "bastion" {
  metadata {
    name      = "bastion-token"
    namespace = "kube-system"
    annotations = {
      "kubernetes.io/service-account.name" = kubernetes_service_account_v1.bastion.metadata[0].name
    }
  }

  type = "kubernetes.io/service-account-token"
  depends_on = [ kubernetes_cluster_role_binding.bastion_access ]
}