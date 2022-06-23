module "tls-proxy" {
  source         = "../../terraform-modules/k8s-vault-tls-proxy"
  SecretPath     = var.Settings.clusters[var.Cluster].tlsProxyPath
  Color          = var.Color
  ElasticProxyNS = var.Settings.clusters[var.Cluster].elasticProxy
  Cluster        = var.Cluster
  Settings       = var.Settings
}
