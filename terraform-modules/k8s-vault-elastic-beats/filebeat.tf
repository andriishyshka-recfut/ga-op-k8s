resource "helm_release" "filebeat" {
  name      = "filebeat"
  chart     = "${path.module}/filebeats"
  wait      = true
  atomic    = true
  namespace = "elastic"
  values = [
    yamlencode(local.beatsValues)
  ]
  set {
    name  = "beatsVersion"
    value = local.version
  }
}