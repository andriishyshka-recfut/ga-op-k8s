data "google_service_account" "minio_sa" {
  account_id = local.minioServiceAccountId
}

variable "VaultAddress" {}
variable "Cluster" {}

locals {
  minioServiceAccountId     = var.Settings.clusters[var.Cluster].persistent_resources.minio_service_account_id

}

resource "google_service_account_key" "minio_key" {
  service_account_id = data.google_service_account.minio_sa.name
  key_algorithm      = "KEY_ALG_RSA_2048"
  public_key_type    = "TYPE_X509_PEM_FILE"
}

provider "vault" {
  address = var.VaultAddress
}
resource "vault_generic_secret" "minio_sa" {
  path = "secret/sa/minio"

  data_json = <<EOT
{
  "gcs_key" : "${ google_service_account_key.minio_key.private_key }"

EOT

}
