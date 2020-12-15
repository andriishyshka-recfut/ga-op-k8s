
variable "ElasticSettings" {}

variable "BackupSaPrivateKey" {}

variable "GkeClusterConnectionSettings" {}

variable "StoreEsPasswordInVault" {}

locals {
  storeEsPasswordInVault = var.StoreEsPasswordInVault ? 1 : 0
  createNs               = lookup(var.ElasticSettings, "create_ns", 1)
  oidcSetup              = lookup(var.ElasticSettings.elastic.oidc_gcloud, "enabled", "no") == "yes" ? 1 : 0
  oidcRealmName          = lookup(var.ElasticSettings.elastic.oidc_gcloud, "oidc_realm_name", "")
  esValues               = var.ElasticSettings.elastic
  kibanaValues           = var.ElasticSettings.kibana
  ansibleEnvs = merge(var.GkeClusterConnectionSettings, {
    ANSIBLE_STDOUT_CALLBACK = "debug"
    namespace               = local.esValues.namespace
  })
}
