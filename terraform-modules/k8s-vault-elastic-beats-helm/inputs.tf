variable "ElasticSettings" {}
variable "BeatKibanaService" {}
variable "BeatElasticService" {}
variable "logstash_pipelines" {}

locals {
  elasticSettings = var.ElasticSettings
  logstash_password = { for k, v in var.logstash_pipelines : k => data.vault_generic_secret.logstash_es_creds[k].data.logstash_password }
}
