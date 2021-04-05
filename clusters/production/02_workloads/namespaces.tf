module "namespaces" {
  source   = "../../../terraform-modules/k8s-vault-namespaces"
  Settings = var.Settings
  Cluster  = "production"
  Color    = local.activeCluster
  depends_on = [

  ]
}
