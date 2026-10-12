

module "minio" {
  source                       = "../../../terraform-modules/k8s-vault-minio-helm"
  Settings                     = var.Settings
  Cluster                      = var.Cluster
  Color                        = var.Color
  GkeClusterConnectionSettings = local.gkeClusterConnectionSettings
}
