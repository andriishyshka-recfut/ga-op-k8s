variable "Cluster" {}
variable "Color" {}
variable "Settings" {}
variable "SecretPath" {
  default = "wl/etl"
}
variable "artifactoryRepoDomain" {}

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
  clients               = nonsensitive(toset(data.vault_kv_secrets_list_v2.etl_clients_list.names))
  namespace             = "etl"
  observerTag           = var.Settings.clusters[var.Cluster].versions.etl.observer_tag
  operatorTag           = var.Settings.clusters[var.Cluster].versions.etl.operator_tag
  ansibleScriptsTag     = var.Settings.clusters[var.Cluster].versions.etl.ansible_scripts_tag
  caminoTag             = var.Settings.clusters[var.Cluster].versions.etl.camino_tag
  gs2s3Tag              = var.Settings.clusters[var.Cluster].versions.etl.gs2s3_tag
  elasticCertsPath      = "secret/es-creds-compose-prod"
  elasticSecretsPrefix  = var.Cluster == "production" ? "" : "-ext"
  elasticSecretsPath    = var.Cluster == "production" ? "/secret/data/es-creds-compose-prod/metaCamino" : "/secret/data/elasticsearch-admin/elastic7-v2"
  elasticSecretsPathNew = var.Cluster == "production" ? "secret/data/es-creds-compose-prod/metaCamino" : "secret/data/elasticsearch-admin/elastic7-v2"
  slackKey              = var.Cluster == "production" ? "gemini_etl-live" : "gemini_etl-test"
  slackToken            = replace(data.vault_generic_secret.slack.data[local.slackKey], "https://hooks.slack.com/services/", "")
  etlVault              = merge(data.vault_generic_secret.api_keys.data, { slacktoken = local.slackToken })
  #minio_endpoints       = var.Settings.clusters[var.Cluster].versions.etl.minio_endpoints
  operatorValues = {
    operatorTag        = local.operatorTag
    ansibleScriptsTag  = local.ansibleScriptsTag
    caminoTag          = local.caminoTag
    gs2s3Tag           = local.gs2s3Tag
    Cluster            = var.Cluster
    Color              = var.Color
    vaultRole          = local.namespace
    monNS              = local.namespace
    elasticSecretsPath = local.elasticSecretsPath
  }

}




