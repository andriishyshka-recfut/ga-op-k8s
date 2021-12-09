module "kiali" {
  source         = "../../terraform-modules/k8s-kiali"
  Kiali_settings = var.Settings.clusters[var.Cluster].kialiSettings
}
