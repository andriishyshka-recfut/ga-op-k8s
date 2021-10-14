
data "vault_generic_secret" "gmail_creds" {
  path ="secret/camel-k/gmail-credentials"
}

resource "kubernetes_secret" "gmail_creds" {

  metadata {
    name      = "gmail-credentials"
    namespace = local.camelNs
  }

  data = data.vault_generic_secret.gmail_creds.data

  depends_on = [

  ]

}
