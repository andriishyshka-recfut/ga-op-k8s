variable "Cluster" {}
variable "Color" {}
variable "SecretPath" {
  default = "etl"
}

# data "vault_generic_secret" "clients" {
#   # for_each = nonsensitive(local.projects)
#   for_each = local.clients
#   path     = "secret/${var.SecretPath}/clients/${each.value}"
# }

data "vault_kv_secrets_list_v2" "etl_clients_list" {
  mount = "secret"
  name  = "${var.SecretPath}/clients"
}


locals {
  clients   = nonsensitive(toset(data.vault_kv_secrets_list_v2.etl_clients_list.names))
  namespace = "etl"
}

