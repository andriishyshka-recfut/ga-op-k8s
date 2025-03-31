resource "kubernetes_limit_range_v1" "tekton_limitrange_main" {
  for_each = local.resources
  metadata {
    name = "tekton-limitrange"
    namespace = each.key
  }
  spec {
    limit {
      type = "Container"
      default = {
        cpu    = each.value.default.cpu
        memory = each.value.default.memory
      }
      default_request = {
        cpu    = each.value.defaultRequest.cpu
        memory = each.value.defaultRequest.memory
      }
      max = {
        cpu    = each.value.max.cpu
        memory = each.value.max.memory
      }
      min = {
        cpu    = each.value.min.cpu
        memory = each.value.min.memory
      }
    }
  }
}