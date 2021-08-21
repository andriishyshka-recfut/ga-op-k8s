

terraform {
  backend "gcs" {
    bucket = "terraform-state-222"
    prefix = "tf-workloads-harbor/state-4"
  }
}


module "harbor" {
  source                       = "../../../terraform-modules/k8s-vault-harbor"
  DoRestoreFromBackup          = true
  GkeClusterConnectionSettings = local.gkeClusterConnectionSettings
  # depends_on          = [module.namespaces, module.minio]
}
