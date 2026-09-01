resource "kubernetes_namespace" "ns" {
  for_each = local.namespaceNames
  metadata {
    name = each.key
    labels = {
      istio-injection                      = lookup(each.value, "istio", "enabled")
      "pod-security.kubernetes.io/enforce" = lookup(each.value, "podSecurityPolicy", "baseline")
    }
  }
}

resource "kubernetes_limit_range" "limit" {
  for_each = local.namespaceNames
  metadata {
    name      = "default-limit-range"
    namespace = each.key
  }
  spec {
    limit {
      type = "Container"
      default_request = {
        cpu    = "20m"
        memory = "50Mi"
      }
    }
  }
  depends_on = [
    kubernetes_namespace.ns
  ]
}


resource "kubernetes_role_binding" "developers_admins" {
  for_each = local.namespaceAdmins
  metadata {
    name      = "developers-admins"
    namespace = each.key
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "admin"
  }
  dynamic "subject" {
    for_each = toset(flatten(each.value))
    content {
      kind      = "User"
      name      = subject.key
      api_group = "rbac.authorization.k8s.io"
    }
  }
  depends_on = [
    kubernetes_namespace.ns
  ]
}

resource "kubernetes_cluster_role" "developers_access_role" {
  count = local.devAccessAllowed
  metadata {
    name = "developers-access"
  }

  rule {
    api_groups = [""]
    resources  = ["services", "pods", "secrets", "pods/log"]
    verbs      = ["get", "list", "watch", "delete"]
  }
  rule {
    api_groups = [""]
    resources  = ["pods/portforward"]
    verbs      = ["get", "list", "create", "delete"]

  }
  rule {
    api_groups = [""]
    resources  = ["pods/exec"]
    verbs      = ["create", "delete"]
  }
  rule {
    api_groups = ["batch"]
    resources  = ["cronjobs"]
    verbs      = ["get", "list"]
  }
  rule {
    api_groups = ["batch"]
    resources  = ["jobs"]
    verbs      = ["create", "get", "list"]
  }
}

resource "kubernetes_cluster_role" "list_ns_role" {
  count = local.devAccessAllowed
  metadata {
    name = "list-ns"
  }

  rule {
    api_groups = [""]
    resources  = ["namesapces"]
    verbs      = ["get", "list"]

  }
}
resource "kubernetes_cluster_role_binding" "developers_groups_binding" {
  count = local.devAccessAllowed
  metadata {
    name = "developers-list-ns"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "list-ns"
  }
  dynamic "subject" {
    for_each = toset(flatten(local.developers))
    content {
      kind      = "Group"
      name      = subject.key
      api_group = "rbac.authorization.k8s.io"
    }
  }
  depends_on = [
    kubernetes_namespace.ns,
    kubernetes_cluster_role.list_ns_role
  ]
}

resource "kubernetes_role_binding" "developers_groups_binding" {
  for_each = local.namespaceDevAccess
  metadata {
    name      = "developers-access"
    namespace = each.key
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "developers-access"
  }
  dynamic "subject" {
    for_each = toset(flatten(local.developers))
    content {
      kind      = "Group"
      name      = subject.key
      api_group = "rbac.authorization.k8s.io"
    }
  }
  depends_on = [
    kubernetes_namespace.ns,
    kubernetes_cluster_role.developers_access_role
  ]
}

resource "kubernetes_cluster_role_binding" "op_recordedfuture_cluster_admin_binding" {
  metadata {
    name = "op-cluster-admin"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "Group"
    api_group = "rbac.authorization.k8s.io"
    name      = "gke-security-groups-rf-op@geminiadvisory.io"
  }
}
