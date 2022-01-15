
locals {
  cppfeedServiceAccountId     = var.Settings.clusters[var.Cluster].persistent_resources.cppfeed_sa

}


resource "google_service_account" "cppfeed_service_account" {
  account_id   = local.cppfeedServiceAccountId
  display_name = "camel-k cppfeed Service Account"
  lifecycle {
    prevent_destroy = true
  }
}

resource "google_service_account_key" "cppfeed_key" {
  service_account_id = google_service_account.cppfeed_service_account.name
  key_algorithm      = "KEY_ALG_RSA_2048"
  public_key_type    = "TYPE_X509_PEM_FILE"
}


resource "vault_generic_secret" "cppfeed_sa" {
  path = "secret/sa/camel-cppfeed"

  data_json = <<EOT
{
  "gcs_key" : "${ google_service_account_key.cppfeed_key.private_key }"
}
EOT

}
