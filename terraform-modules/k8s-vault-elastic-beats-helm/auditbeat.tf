
resource "helm_release" "auditbeat" {
  name      = "auditbeat-test"
  chart     = "${path.module}/charts/auditbeat"
  wait      = true
  atomic    = true
  timeout   = 360
  namespace = local.elasticSettings.globalSettings.namespace
  values = [
    templatefile("${path.module}/auditbeat-values.tftpl", merge(local.elasticSettings.globalSettings, { kibana = var.BeatKibanaService, elastic = var.BeatElasticService }))
  ]
  depends_on = [
    kubernetes_job.beats_users
  ]
}
