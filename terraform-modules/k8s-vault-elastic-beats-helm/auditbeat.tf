
resource "helm_release" "auditbeat" {
  for_each  = var.auditbeats_setttings
  name      = lookup(each.value, "name", each.key)
  chart     = "${path.module}/charts/auditbeat"
  wait      = true
  atomic    = true
  timeout   = 360
  namespace = local.elasticSettings.globalSettings.namespace
  values = [
    templatefile("${path.module}/templates/helm_values/auditbeat-values.tftpl",
      merge(local.elasticSettings.globalSettings, {
        name     = lookup(each.value, "name", each.key),
        settings = each.value
    }))
  ]
  depends_on = [
    kubernetes_secret.auditbeat_creds,
    kubernetes_secret.auditbeat_elastic_ca,
    kubernetes_secret.auditbeat_elastic_pass,
    kubernetes_job.auditbeat_users
  ]
  set = [{
    name  = "priorityClassName"
    value = kubernetes_priority_class.beats.metadata.0.name
  }]
}
