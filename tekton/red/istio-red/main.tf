module "k8s-istio" {
  source   = "../../../terraform-modules/k8s-istio"
  Settings = var.Settings
  Cluster  = var.Cluster
  Color    = var.Color
}

module "k8s-istio-lb" {
  source   = "../../../terraform-modules/k8s-istio-lb"
  Settings = var.Settings
  Cluster  = var.Cluster
  Color    = var.Color
  depends_on = [
    module.k8s-istio
  ]
}
