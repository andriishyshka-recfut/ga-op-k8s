locals {

  beats_values = yamldecode(file("${path.module}/beats_values.yaml"))

}




resource "helm_release" "beat" {
  name   = "beats"
  chart  = "${path.module}/beats"
  wait   = true
  atomic = true
  values = [
    yamlencode(local.beats_values)
  ]

}
