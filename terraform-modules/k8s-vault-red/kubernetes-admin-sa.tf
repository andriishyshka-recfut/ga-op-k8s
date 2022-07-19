resource "kubernetes_service_account" "k8s_cluster_admin" {

  metadata {
    name      = "k8s-admin"
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role_binding" "cluster_admin_role_binding" {
  metadata {
    name = "k8s-admin"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "k8s-admin"
    namespace = "kube-system"
  }
}

data "kubernetes_secret" "cluster_admin_creds" {
  metadata {
    name      = kubernetes_service_account.k8s_cluster_admin.default_secret_name
    namespace = "kube-system"
  }
}
