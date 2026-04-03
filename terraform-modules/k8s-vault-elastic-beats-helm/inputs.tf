variable "ElasticSettings" {}
variable "logstash_list" {}
variable "filebeats_settings" {}
variable "Cluster" {}
variable "Color" {}

locals {
  filebeat_workload_type     = "daemonset"
  filebeat_check_script_path = "../../terraform-modules/k8s-vault-elastic-beats-helm/filebeats_check.py"
  workload_check_module_path = "../../references/workload-check/workload-readiness.py"
  elasticSettings            = var.ElasticSettings
  logstash_pipelines_creds   = { for k, v in var.logstash_list : k => merge(v, { "password" : "${data.vault_generic_secret.logstash_es_creds[k].data.logstash_api_password}" }) }
  filebeat_image_tags        = { for name, data in var.filebeats_settings : name => lookup(var.filebeats_settings[name], "imageTag", var.ElasticSettings.globalSettings.imageTag) }
  filebeat_groups_list       = { for name, data in var.filebeats_settings : name => data if data.log_groups != "" }
  BeatKibanaService          = "kb-ga"
  BeatElasticService         = "red-coor.elastic.svc.cluster.local"
  filebeats_jobs             = { for name, data in var.filebeats_settings : name => templatefile("${path.module}/templates/users/filebeat_user.tftpl", { settings = data, password = random_password.filebeat_password[name].result }) }
  headless_cert              = {
    name = "elastic-headless"
    namespace = var.ElasticSettings.globalSettings.namespace
    pki = {
      name = "pki-elastic-int"
      role = "headless"
    }
    vault_addr = "https://vault.p.regemini.io"
    kube_auth = {
      role = "elastic"
    }
    cluster = var.Cluster
    color  = var.Color
  }
}

