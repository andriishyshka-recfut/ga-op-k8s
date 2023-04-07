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

