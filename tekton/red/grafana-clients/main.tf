module "grafana" {
  source   = "../../../terraform-modules/k8s-vault-grafana-for-clients"
  Settings = var.Settings
  Cluster  = var.Cluster
  Color    = var.Color
}
