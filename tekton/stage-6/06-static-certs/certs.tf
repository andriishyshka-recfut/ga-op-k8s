module "static-certificates" {
  source       = "../../../terraform-modules/k8s-vault-static-certs"
  Cluster      = var.Cluster
  Color        = var.Color
  Settings     = var.Settings
  VaultAddress = var.VaultAddress
}
