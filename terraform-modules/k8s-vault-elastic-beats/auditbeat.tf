resource "helm_release" "auditbeat" {
  name      = "auditbeat"
  chart     = "${path.module}/auditbeat"
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
  set {
    name  = "elastic.password"
    value = data.kubernetes_secret.es_pass.data.elastic
  }
}
