# Need to run disable load balancer service on old cluster

resource "helm_release" "istio_ingress_lb" {
  name       = "istio-ingressgateway-lb"
  chart      = "gateway"
  repository = "https://istio-release.storage.googleapis.com/charts"
  wait       = true
  atomic     = true
  namespace  = "istio-ingress"
  set {
    name  = "service.type"
    value = "LoadBalancer"
  }
  set {
    name  = "autoscaling.minReplicas"
    value = 2
  }
  set {
    name  = "service.loadBalancerIP"
    value = local.load_balancer_ip
  }
}
