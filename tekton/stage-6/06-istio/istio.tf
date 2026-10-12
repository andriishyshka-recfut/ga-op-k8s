module "k8s-istio" {
  source   = "../../../terraform-modules/k8s-istio-lb"
  Settings = var.Settings
  Cluster  = var.Cluster
  Color    = var.Color
  RepositoryDomain = local.artifactoryRepoDomain
}

