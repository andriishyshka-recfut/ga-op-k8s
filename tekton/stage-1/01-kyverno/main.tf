module "kyverno" {
  source   = "../../../terraform-modules/k8s-vault-kyverno"
  Cluster  = var.Cluster
  Color    = var.Color
  Settings = var.Settings
}
