
variable "ElasticSettings" {}

variable "GkeClusterConnectionSettings" {}

variable "StoreEsPasswordInVault" {}

variable "Cluster" {}

variable "Settings" {}

data "google_project" "current_project" {
}

locals {
  storeEsPasswordInVault = var.StoreEsPasswordInVault ? 1 : 0
  oidcSetup              = lookup(var.ElasticSettings.elastic.oidc_gcloud, "enabled", "no") == "yes" ? 1 : 0
  oidcRealmName          = lookup(var.ElasticSettings.elastic.oidc_gcloud, "oidc_realm_name", "")
  esValues               = var.ElasticSettings.elastic
  kibanaValues           = var.ElasticSettings.kibana
  ansibleEnvs = merge(var.GkeClusterConnectionSettings, {
    ANSIBLE_STDOUT_CALLBACK = "debug"
    namespace               = local.esValues.namespace
  })
  currentProject = split("/", data.google_project.current_project.id)[1]
  injectApmCreds = toset(flatten([
    for namespace in var.Settings.clusters[var.Cluster].namespaces : [namespace.name] if lookup(namespace, "injectApmCreds", false) && local.esValues.apm.enabled == "yes"
  ]))
  apmCredsToggle = lookup(local.esValues.apm, "enabled", "no") == "yes" ? 1 : 0
}
