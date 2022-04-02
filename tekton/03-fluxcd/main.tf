
# module "fluxcd" {
#   source = "../../terraform-modules/k8s-vault-fluxcd"
#   Cluster = var.Cluster
#   Color = var.Color
# }

provider "flux" {
  # alias = "fluxcd"
}
