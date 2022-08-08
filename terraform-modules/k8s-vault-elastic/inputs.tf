
variable "ElasticSettings" {}

variable "GkeClusterConnectionSettings" {}

variable "StoreEsPasswordInVault" {}

variable "Cluster" {}

variable "Settings" {}

variable "Color" {}

variable "MinioAddress" {}

variable "BackupBucketName" {}

variable "BackupBucketBasePath" {}

variable "OidcRedirectUri" {}



locals {
  storeEsPasswordInVault = var.StoreEsPasswordInVault ? 1 : 0
  oidcSetup              = lookup(var.ElasticSettings.elastic.oidc_gcloud, "enabled", "no") == "yes" ? 1 : 0
  oidcRealmName          = lookup(var.ElasticSettings.elastic.oidc_gcloud, "oidc_realm_name", "")
  samlSetup              = lookup(var.ElasticSettings.elastic.saml_gcloud, "enabled", "no") == "yes" ? 1 : 0
  slackNotificationSetup = lookup(var.ElasticSettings.elastic.slack_notification, "enabled", "no") == "yes" ? 1 : 0
  smtpNotificationSetup  = lookup(var.ElasticSettings.elastic.smtp_notification, "enabled", "no") == "yes" ? 1 : 0
  esValues               = var.ElasticSettings.elastic
  version                = var.Settings.clusters[var.Cluster][var.Color].elasticsearch.cluster[local.esValues.esName]
  monUrl                 = var.Settings.MonElasticFQDN
  gcsSetup               = lookup(var.ElasticSettings.elastic, "gcs_enable", "no") == "yes" ? 1 : 0
  ansibleEnvs = merge(var.GkeClusterConnectionSettings, {
    ANSIBLE_STDOUT_CALLBACK = "debug"
    namespace               = local.esValues.namespace
  })
  currentProject = var.Settings.gcpProject
  injectApmCreds = toset(flatten([
    for namespace in var.Settings.clusters[var.Cluster].namespaces : [namespace.name] if lookup(namespace, "injectApmCreds", false) && local.esValues.apm.enabled == "yes"
  ]))
  apmCredsToggle = lookup(local.esValues.apm, "enabled", "no") == "yes" ? 1 : 0
}
