module "plantuml" {
  source         = "../../terraform-modules/k8s-vault-plantuml"
  plantuml_list  = var.Settings.clusters[var.Cluster][var.Color].plantuml
}