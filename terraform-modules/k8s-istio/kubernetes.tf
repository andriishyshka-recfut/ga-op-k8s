resource "kubernetes_cluster_role" "node_list" {
  count = local.bastion_expose_toggle
  metadata {
    name = "node-list"
  }

  rule {
    api_groups = [""]
    resources  = ["nodes"]
    verbs      = ["list"]
  }
}

resource "kubernetes_cluster_role_binding" "bastion_anon_access" {
  count = local.bastion_expose_toggle
  metadata {
    name = "bastion-access"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "node-list"
  }
  subject {
    kind      = "User"
    name      = "system:anonymous"
    api_group = "rbac.authorization.k8s.io"
  }
  depends_on = [
    kubernetes_cluster_role.node_list
  ]
}
