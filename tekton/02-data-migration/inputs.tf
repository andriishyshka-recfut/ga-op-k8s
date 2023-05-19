locals {
  prod_runs = var.Cluster == "production" ? 1 : 0
  sandbox_runs = var.Cluster == "production" ? 0 : 1
}