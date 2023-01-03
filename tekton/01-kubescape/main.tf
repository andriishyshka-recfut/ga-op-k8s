module "kubescape" {
  source   = "../../terraform-modules/k8s-vault-kubescape"
  Settings = var.Settings
  Cluster  = var.Cluster
  Color    = var.Color
}
