
variable "elastic_settings" {}

variable "backup_sa_private_key" {}

variable "gke_cluster_connection_settings" {}

variable "store_es_password_in_vault" {}

locals {
  store_es_password_in_vault = var.store_es_password_in_vault ? 1 : 0
  create_ns                  = lookup(var.elastic_settings, "create_ns", 1)
  oidc_setup                 = lookup(var.elastic_settings.elastic.oidc_gcloud, "enabled", "no") == "yes" ? 1 : 0
  oidc_realm_name = lookup(var.elastic_settings.elastic.oidc_gcloud, "oidc_realm_name", "")
  es_values                  = var.elastic_settings.elastic
  kibana_values              = var.elastic_settings.kibana
  ansible_envs = merge(var.gke_cluster_connection_settings, {
    ANSIBLE_STDOUT_CALLBACK = "debug"
    namespace               = local.es_values.namespace
  })
}
