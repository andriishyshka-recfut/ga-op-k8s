

module "minio" {
  source   = "../../../terraform-modules/k8s-vault-minio"
  Settings = var.Settings
  Cluster  = "sandbox"
  Color    = "green"
}
