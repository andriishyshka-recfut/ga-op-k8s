
module "tarantool" {
  source                       = "../../terraform-modules/k8s-vault-tarantool"
  Settings                     = var.Settings
  Cluster                      = var.Cluster
  Color                        = var.Color
}
