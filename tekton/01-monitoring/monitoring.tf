
locals {
  monitoringEs = yamldecode(file("monitoring_elastic_settings.yaml"))
}

module "prometheus" {
  source              = "../../terraform-modules/k8s-vault-prometheus"
  OidcSecretVaultPath = "secret/oidc_google_prod"
  Settings            = var.Settings
  Cluster             = var.Cluster
  Color               = var.Color
}

module "prometheus-addons" {
  source              = "../../terraform-modules/k8s-vault-prometheus-addons"
  OidcSecretVaultPath = "secret/oidc_google_prod"
  Settings            = var.Settings
  Cluster             = var.Cluster
  Color               = var.Color
  depends_on = [
    module.prometheus
  ]
}
