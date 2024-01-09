
module "tarantool" {
  count                        = var.Cluster == "production" && var.Color != "red" ? 0 : 1
  source                       = "../../../terraform-modules/k8s-vault-tarantool-helm"
  Settings                     = var.Settings
  Cluster                      = var.Cluster
  Color                        = var.Color
}
