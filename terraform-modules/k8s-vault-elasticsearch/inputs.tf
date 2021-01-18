
variable "ElasticSettings" {}

variable "GkeClusterConnectionSettings" {}

variable "StoreEsPasswordInVault" {}

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
}
