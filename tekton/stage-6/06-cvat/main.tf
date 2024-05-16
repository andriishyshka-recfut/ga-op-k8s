module "cvat" {
  count    = var.Cluster == "sandbox" ? 1 : 0
  source   = "../../../terraform-modules/k8s-vault-cvat"
  Cluster  = var.Cluster
  Color    = var.Color
  Settings = var.Settings
}
