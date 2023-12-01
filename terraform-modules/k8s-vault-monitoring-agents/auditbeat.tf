data "kubernetes_secret" "es_pass" {
  metadata {
    name      = "monitoring-es-elastic-user"
    namespace = "monitoring"
  }
}

resource "helm_release" "auditbeat" {
  name      = "auditbeat"
  chart     = "${path.module}/auditbeat"
  wait      = true
  atomic    = true
  namespace = "monitoring"
  set {
    name  = "elastic.password"
    value = data.kubernetes_secret.es_pass.data.elastic
  }
  set {
    name  = "tag"
    value = "7.17.15"
  }
}
