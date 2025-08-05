
resource "helm_release" "auditbeat" {
  name      = "auditbeat"
  chart     = "${path.module}/charts/auditbeat"
  wait      = true
  atomic    = true
  timeout   = 360
  namespace = local.elasticSettings.globalSettings.namespace
  values = [
    templatefile("${path.module}/templates/helm_values/auditbeat-values.tftpl", merge(local.elasticSettings.globalSettings, { kibana = local.BeatKibanaService, elastic = local.BeatElasticService }))
  ]
  depends_on = [
    kubernetes_job.beats_users
  ]
  set = [{
    name  = "priorityClassName"
    value = kubernetes_priority_class.beats.metadata.0.name
  }]
}
