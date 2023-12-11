
data "kubernetes_secret" "apm_token" {
  count = local.apmCredsToggle
  metadata {
    name      = "apm-${local.esValues.esName}-apm-token"
    namespace = local.esValues.namespace
  }
  depends_on = [null_resource.ansible_validate_resources]
}
/*
resource "kubernetes_secret" "apm_token" {
  for_each = local.injectApmCreds
  metadata {
    name      = local.apmToken
    namespace = each.key
  }

  data = { "secret-token" = lookup(data.kubernetes_secret.apm_token[0].data, "secret-token") }

}
*/