variable "Projects" {}
variable "Color" {}

data "vault_generic_secret" "clients" {
  for_each = local.projects
  path     = "secret/tls-proxy/projects/${each.value}"
}

data "vault_generic_secret" "basic_auth" {
  for_each = nonsensitive(local.projects_haproxy)
  path     = "secret/tls-proxy/basic-auth/${each.key}"
}

locals {
  projects = toset(var.Projects)
  projects_settings = {
    for project in local.projects : project => lookup(data.vault_generic_secret.clients[project].data, "crt_installed", false) ? 0 : 1
  }
  projects_setup_csr = { for key, val in local.projects_settings : key => val if val == 1 }
  project_data       = { for project, tmp in local.projects : project => data.vault_generic_secret.clients[project].data }
  projects_haproxy = {
    for project, values in local.project_data : project => values if lookup(data.vault_generic_secret.clients[project].data, "basic_auth", false)
  }
  projects_wo_haproxy = {
    for project, values in local.project_data : project => values if !lookup(data.vault_generic_secret.clients[project].data, "basic_auth", false)
  }
  auth_user_list = {
    for project, tmp in local.projects_haproxy : project => nonsensitive(join("\n  ", [for user, password in data.vault_generic_secret.basic_auth[project].data : join(" ", ["user", user, "password", bcrypt(password)])]))
  }
}
