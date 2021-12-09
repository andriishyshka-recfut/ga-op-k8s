locals {
  kialiValues = yamldecode(file("${path.module}/charts/kiali-server/values.yaml"))
}

resource "helm_release" "kiali-server" {
  name      = "kiali-server"
  chart     = "${path.module}/charts/kiali-server"
  wait      = true
  atomic    = true
  namespace = "istio-system"
  values = [
    yamlencode(local.kialiValues)
  ]
}
