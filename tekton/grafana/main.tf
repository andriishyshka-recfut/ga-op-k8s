module "grafana-clients" {
  source = "../../terraform-modules/k8s-vault-grafana"
  #   Cluster  = var.Cluster
  #   Settings = var.Settings
}
