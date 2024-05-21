module "sonarqube" {
  source   = "../../terraform-modules/k8s-vault-harbor"
  Settings = var.Settings
  Cluster  = var.Cluster
  Color    = var.Color
}