data "kubernetes_secret" "es_password" {
  count = local.storeEsPasswordInVault
  metadata {
    name      = "${local.esValues.esName}-es-elastic-user"
    namespace = local.esValues.namespace
  }
  depends_on = [helm_release.elasticsearch]
}


resource "vault_generic_secret" "es_admin_creds" {
  count = local.storeEsPasswordInVault
  path  = "secret/elasticsearch-admin/${local.esValues.esName}"

  data_json = <<EOT
  {
    "username": "elastic",
    "password": "${data.kubernetes_secret.es_password[1].data.elastic}"
  }
EOT
}
