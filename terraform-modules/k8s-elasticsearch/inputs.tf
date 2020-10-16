
variable "elastic_settings" {}

variable "backup_sa_private_key" {}

variable "gke_cluster_connection_settings" {}

variable "store_es_password_in_vault" {}

locals {
  store_es_password_in_vault = var.store_es_password_in_vault ? 1 : 0
  es_values                  = var.elastic_settings.elastic
  kibana_values              = var.elastic_settings.kibana
  ansible_envs = merge(var.gke_cluster_connection_settings, {
    ANSIBLE_STDOUT_CALLBACK = "debug"
    namespace               = local.es_values.namespace
  })
}
