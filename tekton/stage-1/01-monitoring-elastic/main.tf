locals {
  ElasticSettings = yamldecode(file("../../red/elastic-monitoring/elastic_settings.yaml")).ElasticSettings
}
module "beats" {
  source                = "../../../terraform-modules/k8s-vault-elastic-beats-helm"
  Cluster               = var.Cluster
  Color                 = var.Color
  ElasticSettings       = local.ElasticSettings
  filebeats_settings    = lookup(var.Settings.clusters[var.Cluster][var.Color], "filebeats", {})
  metricbeats_setttings = lookup(var.Settings.clusters[var.Cluster][var.Color], "metricbeats", {})
  auditbeats_setttings  = lookup(var.Settings.clusters[var.Cluster][var.Color], "auditbeats", {})
  logstash_list         = {}
}
