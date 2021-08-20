
data "google_service_account" "es_server" {
  account_id = "elastic-backup"
}

resource "google_service_account_key" "es_key" {
  service_account_id = data.google_service_account.es_server.name
  # key_algorithm      = "KEY_ALG_RSA_2048"
  # public_key_type    = "TYPE_X509_PEM_FILE"
}
resource "vault_generic_secret" "elastic_sa" {
  path = "secret/sa/elastic"

  data_json = <<EOT
{
  "gcs_key" : "${ google_service_account_key.es_key.private_key }"
}
EOT

}
