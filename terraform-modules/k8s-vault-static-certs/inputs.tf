
variable "Color" {}
variable "Cluster" {}
variable "Settings" {}
variable "VaultAddress" {}

data "vault_kv_secrets_list_v2" "certificates" {
  mount = "secret"
  name  = "misc/certificates"
}

data "vault_generic_secret" "certificates" {
  for_each = local.certs_vault
  path     = "secret/misc/certificates/${each.value}"
}


locals {
  certs_vault = nonsensitive(toset(data.vault_kv_secrets_list_v2.certificates.names))
  certs       = { for cert_name, cert_data in local.certs_vault : cert_name => data.vault_generic_secret.certificates[cert_data].data }
}
