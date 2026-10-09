
module "kafka" {
  source                       = "../../../terraform-modules/k8s-vault-kafka"
  GkeClusterConnectionSettings = local.gkeClusterConnectionSettings
  Cluster                      = var.Cluster
  Settings                     = var.Settings
  Color                        = var.Color
  artifactoryRepoDomain        = local.artifactoryRepoDomain
}
