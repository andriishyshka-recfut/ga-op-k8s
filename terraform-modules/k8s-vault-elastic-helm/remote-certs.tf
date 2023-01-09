data "vault_generic_secret" "remote-certs" {
  count = length(local.globalSettings.remotecerts) > 0 ? 1 : 0
  path  = "secret/elasticsearch-admin/remote-certs"
}

resource "kubernetes_secret" "remote-certs" {
  count = length(local.globalSettings.remotecerts) > 0 ? 1 : 0
  metadata {
    name      = "elastic-remote-certs"
    namespace = local.globalSettings.namespace
  }
  data = data.vault_generic_secret.remote-certs.0.data
}
