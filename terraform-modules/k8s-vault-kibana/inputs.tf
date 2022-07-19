
variable "ElasticSettings" {}

variable "GkeClusterConnectionSettings" {}

variable "Cluster" {}

variable "Settings" {}

variable "Color" {}



locals {
  esValues     = var.ElasticSettings.elastic
  kibanaValues = var.ElasticSettings.kibana
  version      = var.Settings.clusters[var.Cluster][var.Color].elasticsearch.cluster[local.esValues.esName]
  monUrl       = var.Settings.ElasticFQDN
  gcsSetup     = lookup(var.ElasticSettings.elastic, "gcs_enable", "no") == "yes" ? 1 : 0
  ansibleEnvs = merge(var.GkeClusterConnectionSettings, {
    ANSIBLE_STDOUT_CALLBACK = "debug"
    namespace               = local.esValues.namespace
  })
  currentProject = var.Settings.gcpProject
}
