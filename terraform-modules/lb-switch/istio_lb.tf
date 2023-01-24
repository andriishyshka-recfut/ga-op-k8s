resource "null_resource" "stop_istio_lb" {

  triggers = {
    command = md5(local.delete_lb_service)
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = local.delete_lb_service
  }
}

# resource "helm_release" "istio_ingress_lb" {
#   name       = "istio-ingressgateway-lb"
#   chart      = "gateway"
#   repository = "https://istio-release.storage.googleapis.com/charts"
#   wait       = true
#   atomic     = true
#   namespace  = "istio-ingress"
#   set {
#     name  = "service.type"
#     value = "LoadBalancer"
#   }
#   set {
#     name  = "autoscaling.minReplicas"
#     value = 2
#   }
#   set {
#     name  = "service.loadBalancerIP"
#     value = var.Settings.clusters[var.Cluster].load_balancer_ip
#   }
#   set {
#     name  = "service.externalTrafficPolicy"
#     value = "Local"
#   }
#   dynamic "set" {
#     for_each = local.ports
#     content {
#       name  = "service.ports[${set.key}].name"
#       value = set.value["name"]
#     }
#   }
#   dynamic "set" {
#     for_each = local.ports
#     content {
#       name  = "service.ports[${set.key}].protocol"
#       value = set.value["protocol"]
#     }
#   }
#   dynamic "set" {
#     for_each = local.ports
#     content {
#       name  = "service.ports[${set.key}].port"
#       value = set.value["port"]
#     }
#   }
#   dynamic "set" {
#     for_each = local.ports
#     content {
#       name  = "service.ports[${set.key}].targetPort"
#       value = set.value["port"]
#     }
#   }
#   dynamic "set" {
#     for_each = local.ports
#     content {
#       name  = "service.ports[${set.key}].nodePort"
#       value = set.value["nodePort"]
#     }
#   }
# }
