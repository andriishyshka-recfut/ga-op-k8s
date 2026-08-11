module "internal_ingress" {
  source        = "../../../terraform-modules/k8s-ingress-internal"
  Cluster       = var.Cluster
  Settings      = var.Settings
  k8s           = local.gkeClusterConnectionSettings
  resource_type = "services"
}


