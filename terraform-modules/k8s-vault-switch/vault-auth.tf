
resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
  path = "k8s-production-blue"
  tune {
    max_lease_ttl = "2764800s"
  }
}

resource "vault_kubernetes_auth_backend_config" "kubernetes" {
  backend         = "k8s-production-blue"
  kubernetes_host = vault_generic_secret.cluster_token.data["HOST"]
}

