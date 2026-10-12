resource "helm_release" "metricbeat" {
  for_each  = var.metricbeats_setttings
  name      = lookup(each.value, "name", each.key)
  chart     = "${path.module}/charts/metricbeat"
  wait      = true
  atomic    = true
  timeout   = 7200
  namespace = local.elasticSettings.globalSettings.namespace
  values = [
    templatefile("${path.module}/templates/helm_values/metricbeat-values.tftpl",
      merge(local.elasticSettings, {
        name                     = lookup(each.value, "name", each.key)
        settings                 = each.value
        logstash_pipelines_creds = local.logstash_pipelines_creds,
    }))
  ]
  depends_on = [
    kubernetes_secret.metricbeat_creds,
    kubernetes_secret.metricbeat_elastic_ca,
    kubernetes_secret.metricbeat_elastic_pass,
    kubernetes_job.metricbeat_users
  ]
}
