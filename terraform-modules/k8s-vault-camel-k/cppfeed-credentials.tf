
data "vault_generic_secret" "cppfeed_creds" {
  path = "secret/camel-k/weekly-cpp-feed"
}

resource "kubernetes_secret" "cppfeed_creds" {
  count = local.installCount

  metadata {
    name      = "weekly-cpp-feed"
    namespace = local.camelNs
  }

  data = data.vault_generic_secret.cppfeed_creds.data

}


data "vault_generic_secret" "cppfeed_sa" {
  path = "secret/sa/camel-cppfeed"
}
resource "kubernetes_secret" "cppfeed_sa_creds" {
count = local.installCount
  metadata {
    name      = "google-service-account-credentials"
    namespace = local.camelNs
  }

  data = {
    token = data.vault_generic_secret.cppfeed_sa.data.gcs_key
  }


}
