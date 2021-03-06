module "namespaces" {
  source   = "../../../terraform-modules/k8s-vault-namespaces"
  Settings = var.Settings
  Cluster  = var.Cluster
  Color    = local.activeCluster
  depends_on = [

  ]
}
