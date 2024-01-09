variable "ElasticSettings" {}
variable "BeatKibanaService" {}
variable "BeatElasticService" {}
variable "logstash_list" {}

locals {
  filebeat_groups          = var.Settings.clusters[var.Cluster][var.Color].elasticsearch.cluster.filebeat_groups
  elasticSettings          = var.ElasticSettings
  logstash_pipelines_creds = { for k, v in var.logstash_list : k => data.vault_generic_secret.logstash_es_creds[k].data.logstash_api_password }
}
