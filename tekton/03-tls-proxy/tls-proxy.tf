module "tls-proxy" {
  source         = "../../terraform-modules/k8s-vault-tls-proxy"
  Projects       = var.Settings.clusters[var.Cluster].tlsProxy
  Color          = var.Color
  ElasticProxyNS = var.Settings.clusters[var.Cluster].elasticProxy
}
