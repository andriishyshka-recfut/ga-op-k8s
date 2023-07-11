resource "helm_release" "metricbeat" {
  name      = "metricbeat"
  chart     = "${path.module}/charts/metricbeat"
  wait      = true
  atomic    = true
  timeout   = 7200
  namespace = local.elasticSettings.globalSettings.namespace
  values = [
    templatefile("${path.module}/metricbeat-values.tftpl", merge(local.elasticSettings, { kibana = var.BeatKibanaService, elastic = var.BeatElasticService, logstash_password = data.vault_generic_secret.logstash_es_creds[], logstash_pipelines = var.logstash_pipelines}))
  ]
  depends_on = [
    kubernetes_job.beats_users
  ]
}
