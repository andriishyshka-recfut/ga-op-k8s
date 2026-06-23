module "github-arc" {
  source        = "../../../terraform-modules/k8s-vault-github-arc"
  Cluster = var.Cluster
  Color = var.Color
  Settings = var.Settings
}