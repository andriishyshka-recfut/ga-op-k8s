
module "prometheus" {
  source              = "../../../terraform-modules/k8s-vault-prometheus"
  OidcSecretVaultPath = "secret/oidc_google_prod"
  Settings            = var.Settings
  Cluster             = var.Cluster
  Color               = var.Color
}


module "prometheus-addons-red" {
  source              = "../../../terraform-modules/k8s-vault-prometheus-addons-red"
  OidcSecretVaultPath = "secret/oidc_google_prod"
  Settings            = var.Settings
  Cluster             = var.Cluster
  Color               = var.Color
  depends_on = [
    module.prometheus
  ]
}
