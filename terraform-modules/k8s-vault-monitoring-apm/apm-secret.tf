
# data "kubernetes_secret" "apm_token" {
#   count = local.apmCredsToggle
#   metadata {
#     name      = "apm-${local.esValues.esName}-apm-token"
#     namespace = local.esValues.namespace
#   }
# }

# resource "kubernetes_secret" "apm_token" {
#   for_each = local.injectApmCreds
#   metadata {
#     name      = local.apmToken
#     namespace = each.key
#   }

#   data       = { "secret-token" = lookup(data.kubernetes_secret.apm_token[0].data, "secret-token") }
#   depends_on = [data.kubernetes_secret.apm_token]

# }

