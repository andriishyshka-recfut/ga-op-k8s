module "nfs" {
  count    = var.Cluster == "sandbox" ? 1 : 0
  source   = "../../../terraform-modules/k8s-vault-nfs"
  Cluster  = var.Cluster
  Color    = var.Color
  Settings = var.Settings
}
