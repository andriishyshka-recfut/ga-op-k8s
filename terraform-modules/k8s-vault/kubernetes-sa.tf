
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
  depends_on = [kubernetes_service_account.k8s_cluster_admin]
}

resource "kubernetes_secret_v1" "cluster_admin_creds" {
  metadata {
    namespace = "kube-system"
    name      = "sa-k8s-admin"
    annotations = {
      "kubernetes.io/service-account.name" = "k8s-admin"
    }
  }
  type       = "kubernetes.io/service-account-token"
  depends_on = [kubernetes_service_account.k8s_cluster_admin]
}


data "kubernetes_secret" "cluster_admin_creds" {
  metadata {
    name      = "sa-k8s-admin"
    namespace = "kube-system"
  }
  depends_on = [
    kubernetes_secret_v1.cluster_admin_creds
  ]

}


resource "kubernetes_service_account" "vault" {
  metadata {
    name      = "vault"
    namespace = "kube-system"
  }
}

resource "kubernetes_secret_v1" "vault" {
  metadata {
    namespace = "kube-system"
    name      = "sa-vault"
    annotations = {
      "kubernetes.io/service-account.name" = "vault"
    }
  }
  type       = "kubernetes.io/service-account-token"
  depends_on = [kubernetes_service_account.vault]
}

data "kubernetes_secret" "vault" {
  metadata {
    name      = "sa-vault"
    namespace = "kube-system"
  }
  depends_on = [
    kubernetes_service_account.vault,
    kubernetes_secret_v1.vault
  ]
}

resource "kubernetes_cluster_role_binding" "vault" {
  metadata {
    name = "vault-auth"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "system:auth-delegator"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "vault"
    namespace = "kube-system"
  }
  depends_on = [
    kubernetes_service_account.vault
  ]
}

data "kubernetes_service_account" "vault" {
  metadata {
    name      = "vault"
    namespace = "kube-system"
  }
  depends_on = [
    kubernetes_service_account.vault,
    kubernetes_secret_v1.vault
  ]
}
