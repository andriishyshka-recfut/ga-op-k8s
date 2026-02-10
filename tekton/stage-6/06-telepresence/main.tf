module "telepresence" {
  source   = "../../../terraform-modules/k8s-vault-telepresence"
  Settings = var.Settings
  Cluster  = var.Cluster
  Color    = var.Color
}
