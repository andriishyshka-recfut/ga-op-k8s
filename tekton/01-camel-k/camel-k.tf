
module "camel-k" {
  source = "../../terraform-modules/k8s-vault-camel-k"
  VaultAddress = var.VaultAddress
  GkeClusterConnectionSettings = local.gkeClusterConnectionSettings
}
