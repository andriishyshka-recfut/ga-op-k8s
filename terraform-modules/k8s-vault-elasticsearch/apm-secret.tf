
data "kubernetes_secret" "apm_token" {
  count = local.apmCredsToggle
  metadata {
    name      = "apm-elastic7-apm-token" #hardcode secret name
    namespace = local.esValues.namespace
  }
  depends_on = [null_resource.ansible_validate_resources]
}

resource "kubernetes_secret" "apm_token" {
  for_each = local.injectApmCreds
  metadata {
    name      = "es7-apm-token" #hardcode secret name
    namespace = each.key
  }

  data = { "secret-token" = lookup(data.kubernetes_secret.apm_token[0].data, "secret-token") }

}
