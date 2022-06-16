module "ingress" {
  source   = "../../terraform-modules/k8s-vault-ingress"
  Cluster  = var.Cluster
  Settings = var.Settings
  Color    = var.Color
}

