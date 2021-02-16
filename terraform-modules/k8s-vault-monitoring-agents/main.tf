locals {

  beatsValues = yamldecode(file("${path.module}/beats_values.yaml"))

}




resource "helm_release" "beat" {
  name      = "beats"
  chart     = "${path.module}/beats"
  wait      = true
  atomic    = true
  namespace = "monitoring"
  values = [
    yamlencode(local.beatsValues)
  ]

}
