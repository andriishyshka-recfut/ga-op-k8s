data "vault_generic_secret" "kibana_xpack_secrets_vault" {
  for_each = local.kibanaSettings
  path     = each.value.kibana_xpack_secrets
}
resource "helm_release" "kibana" {
  for_each  = local.kibanaSettings
  name      = "kibana-${each.key}"
  chart     = "${path.module}/charts/kibana8"
  wait      = true
  atomic    = true
  timeout   = 2000
  namespace = each.value.namespace
  values = [
    templatefile("${path.module}/kibana-values.tftpl", merge(local.globalSettings, { settings = each.value, kibana_name = each.key, kibana_xpack_secrets = data.vault_generic_secret.kibana_xpack_secrets_vault[each.key].data, order_counter = local.order_counter[each.key] }))
  ]
  set = [
    {
      name  = "elasticsearchHosts"
      value = "https://${local.httpServive}.${local.globalSettings.namespace}.svc:9200"
    },
    {
      name  = "resources.requests.cpu"
      value = local.request.cpu
    },
    {
      name  = "resources.requests.memory"
      value = local.request.memory
    },
    {
      name  = "resources.limits.memory"
      value = local.limit.memory
    },
    {
      name  = "resources.limits.cpu"
      value = local.limit.cpu
    }
  ]
  depends_on = [
    kubernetes_job.kibana_user,
    kubernetes_secret.kibana_elastic_user
  ]
}
