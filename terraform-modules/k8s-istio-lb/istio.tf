# Need to replace
resource "helm_release" "istio_ingress_lb" {
  for_each   = local.istio_ingresses
  name       = "istio-ingressgateway-${each.key}"
  chart      = "gateway"
  repository = "https://istio-release.storage.googleapis.com/charts"
  wait       = true
  atomic     = true
  namespace  = "istio-ingress"
  values = [
    templatefile("${path.module}/values.tftpl", { settings = each.value })
  ]
  # set {
  #   name  = "service.type"
  #   value = "LoadBalancer"
  # }
  # set {
  #   name  = "autoscaling.minReplicas"
  #   value = each.value.minReplicas
  # }
  # set {
  #   name  = "service.loadBalancerIP"
  #   value = each.value.external_ip
  # }
  # set {
  #   name  = "service.externalTrafficPolicy"
  #   value = "Local"
  # }
  # dynamic "set" {
  #   for_each = each.value.ports
  #   content {
  #     name  = "service.ports[${set.key}].name"
  #     value = set.value["name"]
  #   }
  # }
  # dynamic "set" {
  #   for_each = each.value.ports
  #   content {
  #     name  = "service.ports[${set.key}].protocol"
  #     value = set.value["protocol"]
  #   }
  # }
  # dynamic "set" {
  #   for_each = each.value.ports
  #   content {
  #     name  = "service.ports[${set.key}].port"
  #     value = set.value["port"]
  #   }
  # }
  # dynamic "set" {
  #   for_each = each.value.ports
  #   content {
  #     name  = "service.ports[${set.key}].targetPort"
  #     value = set.value["port"]
  #   }
  # }
  # dynamic "set" {
  #   for_each = each.value.ports
  #   content {
  #     name  = "service.ports[${set.key}].nodePort"
  #     value = set.value["nodePort"]
  #   }
  # }
}
