data "vault_generic_secret" "elastic_license" {
  path = local.globalSettings.license.vault_path
}

resource "kubernetes_secret" "elastic_license" {
  metadata {
    name      = "elastic-license"
    namespace = local.globalSettings.namespace
  }
  data = {
    "license.json" = data.vault_generic_secret.elastic_license.data[local.globalSettings.license.name]
  }
}

