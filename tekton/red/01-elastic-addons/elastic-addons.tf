locals {
  ElasticSettings    = yamldecode(file("${path.module}/../01-elastic/elastic_settings.yaml")).ElasticSettings
  MonElasticSettings = yamldecode(file("${path.module}/../elastic-monitoring/elastic_settings.yaml")).ElasticSettings
}
module "kibana" {
  source          = "../../../terraform-modules/k8s-vault-kibana-helm"
  ElasticSettings = local.ElasticSettings
  KibanaSettings  = local.KibanaSettings
  Cluster         = var.Cluster
  Color           = var.Color
  Settings        = var.Settings
}
module "kibana-monitoring" {
  source          = "../../../terraform-modules/k8s-vault-kibana-helm"
  ElasticSettings = local.MonElasticSettings
  KibanaSettings  = local.MonKibanaSettings
  Cluster         = var.Cluster
  Color           = var.Color
  Settings        = var.Settings
}

module "logstash" {
  source           = "../../../terraform-modules/k8s-vault-logstash-pipelines"
  logstash_list    = var.Settings.clusters[var.Cluster][var.Color].logstash
  logstash_version = var.Settings.clusters[var.Cluster].versions.logstash.logstash_version
  Settings         = var.Settings
  Cluster          = var.Cluster
  Color            = var.Color
  depends_on       = [module.kibana]
  RepositoryDomain = local.artifactoryRepoDomain
}

module "beats" {
  source               = "../../../terraform-modules/k8s-vault-elastic-beats-helm"
  Cluster              = var.Cluster
  Color                = var.Color
  ElasticSettings      = local.ElasticSettings
  filebeats_settings   = var.Settings.clusters[var.Cluster][var.Color].filebeats
  metricbeats_setttings = lookup(var.Settings.clusters[var.Cluster][var.Color], "metricbeats", {})
  auditbeats_setttings  = lookup(var.Settings.clusters[var.Cluster][var.Color], "auditbeats", {})
  logstash_list        = var.Settings.clusters[var.Cluster][var.Color].logstash
  depends_on           = [module.kibana]
}


