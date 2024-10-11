
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

module "fluxcd-prometheus-main-rules" {
  source  = "../../../terraform-modules/k8s-vault-fluxcd-resources"
  Cluster = var.Cluster
  Color   = var.Color
  Values  = local.values
}

locals {
  values = {
    kustomizations = {
      prometheus-main-rules = {
        kustomization_path = "./monitoring/prometheus-red/main-rules",
        git_repository     = "gitops"
      }
    }
  }
}
