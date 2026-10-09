
module "external_secrets" {
  source           = "../../../terraform-modules/k8s-vault-external-secrets"
  Cluster          = var.Cluster
  Color            = var.Color
  Settings         = var.Settings
  RepositoryDomain = local.artifactoryRepoDomain
}
