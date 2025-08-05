module "ingress" {
  source   = "../../../terraform-modules/k8s-ingress"
  Cluster  = var.Cluster
  Settings = var.Settings
  k8s     = local.gkeClusterConnectionSettings
}

module "firewall" {
  source   = "../../../terraform-modules/k8s-firewall"
  Cluster  = var.Cluster
  Settings = var.Settings
  k8s     = local.gkeClusterConnectionSettings
}

