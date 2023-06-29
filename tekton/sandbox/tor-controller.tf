
module "tor-controller" {
  source         = "../../terraform-modules/k8s-tor-controller"
  Color          = var.Color
  Cluster        = var.Cluster
  Settings       = var.Settings
}