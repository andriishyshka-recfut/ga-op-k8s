module "namespaces" {
  source   = "../../../terraform-modules/k8s-vault-namespaces"
  Settings = var.Settings
  Cluster  = "sandbox"
  depends_on = [

  ]
}
