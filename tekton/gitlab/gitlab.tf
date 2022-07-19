module "gitlab" {
  source       = "../../terraform-modules/k8s-vault-gitlab"
  Color        = var.Color
  Cluster      = var.Cluster
  Settings     = var.Settings
  VaultAddress = var.VaultAddress
}
