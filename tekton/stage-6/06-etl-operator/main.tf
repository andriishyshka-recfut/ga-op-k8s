
module "etl_operator" {
  source                = "../../../terraform-modules/k8s-vault-etl"
  Cluster               = var.Cluster
  Color                 = var.Color
  Settings              = var.Settings
  artifactoryRepoDomain = local.artifactoryRepoDomain
}
