
module "kafka" {
  source                       = "../../../terraform-modules/k8s-vault-kafka"
  GkeClusterConnectionSettings = local.gkeClusterConnectionSettings
  }
