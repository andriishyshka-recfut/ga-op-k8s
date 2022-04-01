module "backup" {
  source      = "../../terraform-modules/k8s-es-curator"
  Namespace   = "elastic"
  ElasticName = "sandbox"
  NamePrefix  = "backup"
  Actions     = file("${path.root}/es-backup-actions.yaml")
  Settings    = var.Settings
  providers = {
    kubernetes = kubernetes.kubernetes-inactive
  }
}

module "restore" {
  source      = "../../terraform-modules/k8s-es-curator"
  Namespace   = "elastic"
  ElasticName = "sandbox"
  NamePrefix  = "restore-logs"
  Actions     = file("${path.root}/es-restore-actions.yaml")
  Settings    = var.Settings
  depends_on  = [module.backup]
}
