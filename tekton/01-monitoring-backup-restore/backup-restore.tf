locals {
  monitoringEs = yamldecode(file("../01-monitoring/monitoring_elastic_settings.yaml"))
}

module "backup" {
  source      = "../../terraform-modules/k8s-es-curator"
  Namespace   = local.monitoringEs.elastic_settings.elastic.namespace
  ElasticName = local.monitoringEs.elastic_settings.elastic.esName
  NamePrefix  = "backup-service-indexes"
  Actions     = file("${path.root}/backup-actions.yaml")
  Settings    = var.Settings
  providers = {
    kubernetes = kubernetes.kubernetes-inactive
  }
}
module "restore-service-indexes" {
  source      = "../../terraform-modules/k8s-es-curator"
  Namespace   = local.monitoringEs.elastic_settings.elastic.namespace
  ElasticName = local.monitoringEs.elastic_settings.elastic.esName
  NamePrefix  = "restore-service-indexes"
  Actions     = file("${path.root}/restore-actions.yaml")
  Settings    = var.Settings
  depends_on = [
    module.backup
  ]
}
