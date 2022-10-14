variable "SecretPath" {}
variable "ElasticProxyNS" {}
variable "Color" {}
variable "Cluster" {}
variable "Settings" {}
variable "VaultAddress" {}

data "vault_generic_secret" "clients" {
  # for_each = nonsensitive(local.projects)
  for_each = local.projects
  path     = "secret/${var.SecretPath}/projects/${each.value}"
}

data "vault_generic_secret" "basic_auth" {
  for_each = nonsensitive(local.projects_haproxy)
  path     = "secret/${var.SecretPath}/basic-auth/${each.key}"
}

data "vault_kv_secrets_list_v2" "tls-projects" {
  mount = "secret"
  name  = "${var.SecretPath}/projects"
}


locals {
  projects             = nonsensitive(toset(data.vault_kv_secrets_list_v2.tls-projects.names))
  project_setup_pki = {for project, tmp in local.projects : project => data.vault_generic_secret.clients[project].data if lookup(data.vault_generic_secret.clients[project].data, "pki_installed", false)}
  projects_setup_csr   = { for project, tmp in local.projects : project => data.vault_generic_secret.clients[project].data if lookup(data.vault_generic_secret.clients[project].data, "crt_installed", false) }
  project_data         = { for project, tmp in local.projects : project => data.vault_generic_secret.clients[project].data }
  project_data_enabled = { for project, tmp in local.projects : project => data.vault_generic_secret.clients[project].data if lookup(data.vault_generic_secret.clients[project].data, "enabled", false) }
  projects_haproxy     = { for project, values in local.project_data : project => values if lookup(data.vault_generic_secret.clients[project].data, "basic_auth", false) && lookup(data.vault_generic_secret.clients[project].data, "enabled", false) }
  projects_wo_haproxy  = { for project, values in local.project_data : project => values if !lookup(data.vault_generic_secret.clients[project].data, "basic_auth", false) && lookup(data.vault_generic_secret.clients[project].data, "enabled", false) }
  auth_user_list       = { for project, tmp in local.projects_haproxy : project => nonsensitive(join("\n  ", [for user, password in data.vault_generic_secret.basic_auth[project].data : join(" ", ["user", user, "password", bcrypt(password)])])) }
  # ourIps               = ["34.86.176.12", "34.86.109.65", "34.86.175.17", "69.164.208.72", "34.75.65.127"]
}
