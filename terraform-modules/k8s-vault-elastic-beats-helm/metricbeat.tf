resource "helm_release" "metricbeat" {
  name      = "metricbeat"
  chart     = "${path.module}/charts/metricbeat"
  wait      = true
  atomic    = true
  timeout   = 7200
  namespace = local.elasticSettings.globalSettings.namespace
  values = [
    templatefile("${path.module}/metricbeat-values.tftpl", merge(local.elasticSettings, { kibana = var.BeatKibanaService, elastic = var.BeatElasticService, logstash_pipelines_creds = local.logstash_pipelines_creds, , logstash_namespaces = local.logstash_namespaces }))
  ]
  depends_on = [
    kubernetes_job.beats_users
  ]
}
