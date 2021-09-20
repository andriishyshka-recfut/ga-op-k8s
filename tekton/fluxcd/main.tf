
module "fluxcd" {
  source = "../../terraform-modules/k8s-vault-fluxcd"
  Cluster = var.Cluster
  Color = local.activeCluster
}

provider "flux" {
  # alias = "fluxcd"
}
