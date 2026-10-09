module "stakater" {
  source                = "../../../terraform-modules/k8s-stakater-reloader"
  Cluster               = var.Cluster
  Color                 = var.Color
  Settings              = var.Settings
  artifactoryRepoDomain = local.artifactoryRepoDomain
}
