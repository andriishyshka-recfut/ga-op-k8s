resource "kubernetes_cluster_role" "kyverno_reports_controller_nodes" {
  metadata {
    name = "kyverno-reports-controller-nodes"
  }

  rule {
    api_groups = [""]
    resources  = ["nodes"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["nodes/status"]
    verbs      = ["get"]
  }

  rule {
  api_groups = [""]
  resources  = ["podtemplates"]
  verbs      = ["get", "list", "watch"]
}
}

resource "kubernetes_cluster_role_binding" "kyverno_reports_controller_nodes" {
  metadata {
    name = "kyverno-reports-controller-nodes"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.kyverno_reports_controller_nodes.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = "kyverno-reports-controller"
    namespace = "kyverno"
  }
}

resource "kubernetes_cluster_role" "kyverno_admission_nodes_read" {
  metadata { name = "kyverno-admission-nodes-read" }

  rule {
    api_groups = [""]
    resources  = ["nodes"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["nodes/status"]
    verbs      = ["get"]
  }
}

resource "kubernetes_cluster_role_binding" "kyverno_admission_nodes_read" {
  metadata { name = "kyverno-admission-nodes-read" }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.kyverno_admission_nodes_read.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = "kyverno-admission-controller"
    namespace = "kyverno"
  }
}

resource "kubernetes_cluster_role" "kyverno_pdb_generator_background_controller" {
  metadata {
    name = "kyverno-pdb-generator:background-controller"
  }

  rule {
    api_groups = ["policy"]
    resources  = ["poddisruptionbudgets"]
    verbs      = ["create", "get", "list", "watch", "update", "patch", "delete"]
  }
}

resource "kubernetes_cluster_role_binding" "kyverno_pdb_generator_background_controller" {
  metadata {
    name = "kyverno-pdb-generator:background-controller"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.kyverno_pdb_generator_background_controller.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = "kyverno-background-controller"
    namespace = "kyverno"
  }
}
