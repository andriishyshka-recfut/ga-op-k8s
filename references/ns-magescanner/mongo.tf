
data "vault_generic_secret" "mongo_creds" {
  path = "secret/mongo/magescanner"
}


resource "kubernetes_secret" "mongo" {
  metadata {
    name      = "mongo"
    namespace = local.ns
  }

  data = data.vault_generic_secret.mongo_creds.data

}
