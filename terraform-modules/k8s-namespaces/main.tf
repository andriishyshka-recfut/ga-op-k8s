resource "kubernetes_namespace" "ns" {
  for_each = local.namespaces
  metadata {
    name = each.value.name
    labels = {
      istio-injection = "enabled"
    }
  }
}

resource "kubernetes_limit_range" "limit" {
  for_each = local.namespaces
  metadata {
    name      = "default-limit-range"
    namespace = each.value.name
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
}
