resource "random_password" "security_encryptionkey" {
  for_each = local.kibanaSettings
  length   = 48
  special  = false
}

resource "random_password" "reporting_encryptionkey" {
  for_each = local.kibanaSettings
  length   = 48
  special  = false
}

resource "random_password" "encryptedsavedobjects_encryptionkey" {
  for_each = local.kibanaSettings
  length   = 48
  special  = false
}

data "vault_generic_secret" "kibana_xpack_secrets" {
  for_each = local.kibanaSettings
  path     = each.value.kibana_xpack_secrets
}
resource "helm_release" "kibana" {
  for_each  = local.kibanaSettings
  name      = "kibana-${each.key}"
  chart     = "${path.module}/charts/kibana"
  wait      = true
  atomic    = true
  timeout   = 2000
  namespace = each.value.namespace
  values = [
    templatefile("${path.module}/kibana-values.tftpl", merge(local.globalSettings, each.value, { kibana_name = each.key, kibana_xpack_secrets = data.vault_generic_secret.kibana_xpack_secrets[each.key].data }))
  ]
  set {
    name  = "elasticsearchHosts"
    value = "https://${local.httpServive}.${local.globalSettings.namespace}.svc:9200"
  }
  depends_on = [
    kubernetes_job.kibana_user,
    kubernetes_secret.kibana_elastic_user
  ]
}
