module "logstash" {
  source           = "../../terraform-modules/k8s-vault-logstash-pipelines"
  logstash_list    = var.Settings.clusters[var.Cluster][var.Color].logstash
  logstash_version = var.Settings.clusters[var.Cluster].versions.logstash.logstash_version
  Cluster          = var.Cluster
  Color            = var.Color
  Settings         = var.Settings
  depends_on       = [module.kibana]
}
