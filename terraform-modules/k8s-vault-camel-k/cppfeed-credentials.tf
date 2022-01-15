
data "vault_generic_secret" "cppfeed_creds" {
  path ="secret/camel-k/weekly-cpp-feed"
}

resource "kubernetes_secret" "cppfeed_creds" {

  metadata {
    name      = "weekly-cpp-feed"
    namespace = local.camelNs
  }

  data = data.vault_generic_secret.cppfeed_creds.data

}


data "vault_generic_secret" "cppfeed_sa" {
  path ="secret/sa/camel-cppfeed"
}
resource "kubernetes_secret" "cppfeed_sa_creds" {

  metadata {
    name      = "google-service-account-credentials"
    namespace = local.camelNs
  }

  data = {
    token = base64decode(data.vault_generic_secret.cppfeed_sa.data.gcs_key)
  }


}
