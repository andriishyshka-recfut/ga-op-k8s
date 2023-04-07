module "namespaces" {
  source   = "../../terraform-modules/k8s-vault-namespaces-red"
  Settings = var.Settings
  Cluster  = var.Cluster
  Color    = var.Color

}
