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


resource "kubernetes_role_binding" "developers" {
  for_each = local.namespaceAdmins
  metadata {
    name      = "developers"
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

resource "kubernetes_cluster_role" "kubefwd_access_role" {
  metadata {
    name = "kubefwd-access"
  }

  rule {
    api_groups = [""]
    resources  = ["services", "pods"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_role_binding" "kubefwd_groups_binding" {
  for_each = local.namespaceKubefwd
  metadata {
    name      = "kubefwd-groups"
    namespace = each.key
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "kubefwd-access"
  }
  dynamic "subject" {
    for_each = toset(flatten(each.value))
    content {
      kind      = "Group"
      name      = subject.key
      api_group = "rbac.authorization.k8s.io"
    }
  }
  depends_on = [
    kubernetes_namespace.ns,
    kubernetes_cluster_role.kubefwd_access_role
  ]
}
