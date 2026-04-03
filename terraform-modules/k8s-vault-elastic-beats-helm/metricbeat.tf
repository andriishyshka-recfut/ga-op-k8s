resource "helm_release" "metricbeat" {
  name      = "metricbeat"
  chart     = "${path.module}/charts/metricbeat"
  wait      = true
  atomic    = true
  timeout   = 7200
  namespace = local.elasticSettings.globalSettings.namespace
  values = [
    templatefile("${path.module}/templates/helm_values/metricbeat-values.tftpl", merge(local.elasticSettings, { kibana = local.BeatKibanaService, elastic = local.BeatElasticService, logstash_pipelines_creds = local.logstash_pipelines_creds }))
  ]
  depends_on = [
    kubernetes_job.beats_users,
    kubernetes_manifest.certificate_elastic_headless
  ]
}
