locals {
  ElasticSettings = yamldecode(file("${path.module}/../01-elastic/elastic_settings.yaml")).ElasticSettings
}
module "kibana" {
  source          = "../../../terraform-modules/k8s-vault-kibana-helm"
  ElasticSettings = local.ElasticSettings
  KibanaSettings  = local.KibanaSettings
  Cluster         = var.Cluster
  Color           = var.Color
  Settings        = var.Settings
}

module "beats" {
  source             = "../../../terraform-modules/k8s-vault-elastic-beats-helm"
  Cluster            = var.Cluster
  ElasticSettings    = local.ElasticSettings
  filebeats_settings = var.Settings.clusters[var.Cluster][var.Color].filebeats
  logstash_list      = var.Settings.clusters[var.Cluster][var.Color].logstash
  depends_on         = [module.kibana]
}

