
locals {
  monitoringEs = var.Cluster == "production" ? yamldecode(file("../../stage-1/01-monitoring-elastic/monitoring_elastic_settings.yaml")) : yamldecode(file("../../stage-1/01-monitoring-elastic/monitoring_elastic_sandbox.yaml"))
}

# module "monitoring-kibana" {
#   source                       = "../../../terraform-modules/k8s-vault-kibana"
#   ElasticSettings              = local.monitoringEs.elastic_settings
#   GkeClusterConnectionSettings = local.gkeClusterConnectionSettings
#   Cluster                      = var.Cluster
#   Color                        = var.Color
#   Settings                     = var.Settings
# }

# module "monitoring-agents" {
#   source     = "../../../terraform-modules/k8s-vault-monitoring-agents"
#   Cluster    = var.Cluster
#   Color      = var.Color
#   Settings   = var.Settings
#   depends_on = [module.monitoring-kibana]
# }

# module "monitoring-apm" {
#   source                       = "../../../terraform-modules/k8s-vault-monitoring-apm"
#   ElasticSettings              = local.monitoringEs.elastic_settings
#   GkeClusterConnectionSettings = local.gkeClusterConnectionSettings
#   Cluster                      = var.Cluster
#   Color                        = var.Color
#   Settings                     = var.Settings
#   StoreEsPasswordInVault       = false
#   depends_on                   = [module.monitoring-agents]
# }
module "prometheus-addons" {
  source              = "../../../terraform-modules/k8s-vault-prometheus-addons-post"
  OidcSecretVaultPath = "secret/oidc_google_prod"
  Settings            = var.Settings
  Cluster             = var.Cluster
  Color               = var.Color
}



module "fluxcd-prometheus-post-rules" {
  source  = "../../../terraform-modules/k8s-vault-fluxcd-resources"
  Cluster = var.Cluster
  Color   = var.Color
  Values  = local.values
  # k8s     = local.gkeClusterConnectionSettings
  # depends_on = [module.prometheus-addons]
}

locals {
  values = {
    kustomizations = {
      prometheus-post-rules = {
        kustomization_path = "./monitoring/prometheus/post-switching",
        git_repository     = "gitops"
      }
    }
  }
}
