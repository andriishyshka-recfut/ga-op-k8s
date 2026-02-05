variable "Settings" {}
variable "Cluster" {}
variable "k8s" {}

data "vault_generic_secret" "basic_auth" {
  for_each = local.ingress_basic_auth
  path     = "secret/${local.basic_auth_path}/${each.key}"
}

data "vault_kv_secrets_list_v2" "ingress_basic_auth" {
  mount = "secret"
  name  = local.basic_auth_path
}

locals {
  ingressSettings         = var.Settings.clusters[var.Cluster].ingress
  internalIngressSettings = lookup(var.Settings.clusters[var.Cluster], "ingress-internal", {})
  internalStaticIps       = lookup(var.Settings, "internal_static_ips", {})
  certManager             = { for ingress, data in local.ingressSettings : ingress => data if lookup(data, "cert-manager", false) }
  virtualService          = merge([for ingress, data in local.ingressSettings : { for service in data.services : "${ingress}-${lookup(service, "name", service.service)}-${lookup(service, "namespace", service.service)}" => { "service" = "${lookup(service, "name", service.service)}", "ingress" = "${ingress}", "index" = index(data.services, service), "basic_auth" = lookup(service, "basic_auth", false) } }]...)
  basic_auth_path         = var.Settings.clusters[var.Cluster].basic_auth_path
  ingress_basic_auth      = nonsensitive(toset(data.vault_kv_secrets_list_v2.ingress_basic_auth.names))
  auth_user_list          = { for service, service_data in local.virtualService : service => [for user, password in data.vault_generic_secret.basic_auth[service].data : base64encode(join(":", [user, password]))] if lookup(service_data, "basic_auth", false) }
}

