module "minio" {
  source   = "../../../terraform-modules/k8s-vault-minio-red"
  Settings = var.Settings
  Cluster  = var.Cluster
  Color    = var.Color
  GkeClusterConnectionSettings = local.gkeClusterConnectionSettings
}
