module "snapshots" {
  source = "../../../terraform-modules/k8s-vault-pv-snapshots"
  Settings = var.Settings
  Cluster  = var.Cluster
  Color    = var.Color
}
