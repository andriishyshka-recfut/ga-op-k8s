variable "ElasticSettings" {}
variable "BeatKibanaService" {}
variable "BeatElasticService" {}
variable "logstash_pipelines" {}

locals {
  elasticSettings = var.ElasticSettings
  logstash_password = vault_generic_secret.logstash_es_creds.data.logstash_password
}
