

module "velero" {
  source     = "../../../terraform-modules/k8s-vault-velero"
  Settings   = var.Settings
  Cluster    = "sandbox"
  Color      = "green"
  depends_on = [module.minio]
}
