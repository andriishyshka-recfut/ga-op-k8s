
module "fluxcd" {
  source   = "../../../terraform-modules/k8s-vault-fluxcd-helm"
  Cluster  = var.Cluster
  Color    = var.Color
  Settings = var.Settings
}

