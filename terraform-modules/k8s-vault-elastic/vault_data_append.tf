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
  path  = "secret/red/elasticsearch-admin/${local.esValues.esName}"

  data_json = <<EOT
  {
    "username": "elastic",
    "password": "${data.kubernetes_secret.es_password[0].data["elastic"]}"
  }
EOT
}

resource "vault_generic_secret" "apm_creds" {
  count = local.apmCredsToggle
  path  = "secret/red/apm/${local.esValues.esName}-${var.Color}"

  data_json = <<EOT
  {
    "token": "${lookup(data.kubernetes_secret.apm_token[0].data, "secret-token")}"
  }
EOT
}
