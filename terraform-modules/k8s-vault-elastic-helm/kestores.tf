data "vault_generic_secret" "keystores" {
  for_each = local.keystores
  path     = each.value
}

resource "kubernetes_secret" "keystores" {
  for_each = local.keystores
  metadata {
    name      = "${each.key}-credentials"
    namespace = local.globalSettings.namespace
  }
  data       = data.vault_generic_secret.keystores[each.key].data
  depends_on = [data.vault_generic_secret.keystores]
}
