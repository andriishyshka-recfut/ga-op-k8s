


module "backup" {
  source                       = "../../terraform-modules/k8s-es-curator"
  Namespace = "elastic"
  ElasticName = "sandbox"
  NamePrefix = "backup"
  Actions = file("${path.root}/es-backup-actions.yaml")
  providers = {
    kubernetes = kubernetes.kubernetes-inactive
  }
}

module "restore" {
  source                       = "../../terraform-modules/k8s-es-curator"
  Namespace = "elastic"
  ElasticName = "sendbox"
  NamePrefix = "restore-logs"
  Actions = file("${path.root}/es-backup-actions.yaml")
  depends_on = [ module.backup]
}
