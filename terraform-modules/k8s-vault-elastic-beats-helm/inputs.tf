variable "ElasticSettings" {}
variable "BeatKibanaService" {}
variable "BeatElasticService" {}
variable "logstash_list" {}
variable "filebeat_groups" {}

locals {
  filebeat_workload_name     = "filebeat"
  filebeat_workload_type     = "daemonset"
  filebeat_check_script_path = "../../terraform-modules/k8s-vault-elastic-beats-helm/filebeats_check.py"
  workload_check_module_path = "../../references/workload-check/workload-readiness.py"
  elasticSettings          = var.ElasticSettings
  logstash_pipelines_creds = { for k, v in var.logstash_list : k => merge(v, {"password": "${data.vault_generic_secret.logstash_es_creds[k].data.logstash_api_password}"}) }
}
