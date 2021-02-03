module "namespaces" {
  source   = "../../../terraform-modules/k8s-vault-namespaces"
  Settings = var.Settings
  Cluster  = "sandbox"
  Color    = "green"
  depends_on = [

  ]
}
