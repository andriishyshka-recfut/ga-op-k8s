

module "minio" {
  source   = "../../terraform-modules/k8s-vault-minio"
  Settings = var.Settings
  Cluster  = var.Cluster
  Color    = local.activeCluster

}
