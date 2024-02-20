module "logstash" {
  source        = "../../../terraform-modules/k8s-vault-logstash-pipelines"
  logstash_list = var.Settings.clusters[var.Cluster][var.Color].logstash
  Settings      = var.Settings
  Cluster       = var.Cluster
  Color         = var.Color
}
