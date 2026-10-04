module "prometheus" {
  source              = "../../../terraform-modules/k8s-vault-prometheus"
  OidcSecretVaultPath = "secret/oidc_google_prod"
  Settings            = var.Settings
  Cluster             = var.Cluster
  Color               = var.Color
}

module "thanos" {
  source     = "../../../terraform-modules/k8s-vault-thanos"
  Settings   = var.Settings
  Cluster    = var.Cluster
  Color      = var.Color
  depends_on = [module.prometheus]
}
module "prometheus-addons" {
  source                = "../../../terraform-modules/k8s-vault-prometheus-addons"
  OidcSecretVaultPath   = "secret/oidc_google_prod"
  Settings              = var.Settings
  Cluster               = var.Cluster
  Color                 = var.Color
  artifactoryRepoDomain = local.artifactoryRepoDomain
  depends_on            = [module.prometheus]
}

