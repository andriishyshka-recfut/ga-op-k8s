resource "kubernetes_namespace" "ns" {
  for_each = local.namespaceNames
  metadata {
    name = each.value
    labels = {
      istio-injection = "enabled"
    }
  }
}

resource "kubernetes_limit_range" "limit" {
  for_each = local.namespaceNames
  metadata {
    name      = "default-limit-range"
    namespace = each.value
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
  metadata {
    name = "developers-access"
  }

  rule {
    api_groups = [""]
    resources  = ["services", "pods","secrets","pods/log"]
    verbs      = ["get", "list", "watch","delete"]
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
}

resource "kubernetes_cluster_role" "list_ns_role" {
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
  metadata {
    name      = "developers-list-ns"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "list-ns"
  }
  dynamic "subject" {
    for_each = toset(flatten(local.developers))
    content {
      kind      = "User"
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
      kind      = "User"
      name      = subject.key
      api_group = "rbac.authorization.k8s.io"
    }
  }
  depends_on = [
    kubernetes_namespace.ns,
    kubernetes_cluster_role.developers_access_role
  ]
}
