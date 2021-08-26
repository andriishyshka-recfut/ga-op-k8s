module "trac" {
  source   = "../../terraform-modules/k8s-vault-trac"
  Settings = var.Settings
  Cluster  = var.Cluster
  Color    = local.activeCluster
}
