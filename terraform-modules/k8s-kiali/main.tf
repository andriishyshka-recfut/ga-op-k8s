locals {
  kialiValues = yamldecode(file("${path.module}/kiali-server/values.yaml"))
}

resource "helm_release" "kiali-server" {
  name      = "kiali-server"
  chart     = "${path.module}/kiali-server"
  wait      = true
  atomic    = true
  namespace = "istio-system"
  values = [
    yamlencode(local.kialiValues)
  ]
}
