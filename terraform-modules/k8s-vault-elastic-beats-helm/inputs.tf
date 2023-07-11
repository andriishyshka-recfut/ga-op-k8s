variable "ElasticSettings" {}
variable "BeatKibanaService" {}
variable "BeatElasticService" {}

locals {
  elasticSettings = var.ElasticSettings
  logstash_password = vault_generic_secret.logstash_es_creds.data.logstash_password
}
