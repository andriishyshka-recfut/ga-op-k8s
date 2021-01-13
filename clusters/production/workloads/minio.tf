

module "minio" {
  source   = "../../../terraform-modules/k8s-vault-minio"
  Settings = var.Settings
  Cluster  = "production"
  Color    = "blue"
}
