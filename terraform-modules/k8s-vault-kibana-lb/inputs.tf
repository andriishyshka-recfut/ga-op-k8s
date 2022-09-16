
variable "ElasticSettings" {}

variable "GkeClusterConnectionSettings" {}

variable "Cluster" {}

variable "Settings" {}

variable "Color" {}

locals {
  # esValues     = var.ElasticSettings.elastic
  kibanaValues = var.ElasticSettings.kibana
  version      = var.Settings.clusters[var.Cluster][var.Color].elasticsearch.cluster[local.kibanaValues.esName]
  # monUrl       = var.Settings.MonElasticFQDN
  xpackSecurity = lookup(var.ElasticSettings.kibana.xpack_security, "enabled", "no") == "yes" ? 1 : 0
  gcsSetup      = lookup(var.ElasticSettings.kibana, "gcs_enable", "no") == "yes" ? 1 : 0
  ansibleEnvs = merge(var.GkeClusterConnectionSettings, {
    ANSIBLE_STDOUT_CALLBACK = "debug"
    namespace               = local.kibanaValues.namespace
  })
  currentProject = var.Settings.gcpProject
}
