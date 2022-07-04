module "es6-backup" {
  source      = "../../terraform-modules/k8s-es-curator"
  Namespace   = "elastic"
  ElasticName = "sandbox"
  NamePrefix  = "backup"
  Actions     = file("${path.root}/es6-backup-actions.yaml")
  Settings    = var.Settings
  providers = {
    kubernetes = kubernetes.kubernetes-inactive
  }
}

module "es6-restore" {
  source      = "../../terraform-modules/k8s-es-curator"
  Namespace   = "elastic"
  ElasticName = "sandbox"
  NamePrefix  = "restore-logs"
  Actions     = file("${path.root}/es6-restore-actions.yaml")
  Settings    = var.Settings
  depends_on  = [module.es6-backup]
}
