resource "helm_release" "filebeat" {
  name      = "filebeat"
  chart     = "${path.module}/charts/filebeat"
  wait      = true
  atomic    = true
  timeout   = 7200
  namespace = local.elasticSettings.globalSettings.namespace
  values = [
    templatefile("${path.module}/filebeat-values.tftpl", merge(local.elasticSettings.globalSettings, { kibana = var.BeatKibanaService, elastic = var.BeatElasticService }))
  ]
  depends_on = [
    kubernetes_job.beats_users
  ]
}
