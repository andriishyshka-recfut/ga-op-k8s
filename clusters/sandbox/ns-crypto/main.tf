provider "vault" {
  address = "https://vault.infra.digaweb.com"
}

data "vault_generic_secret" "k8s_auth" {
  path = "secret/kubernetes-sandbox"
}

provider "helm" {
  # alias = "helm"
  kubernetes {
    load_config_file       = false
    host                   = data.vault_generic_secret.k8s_auth.data.HOST
    cluster_ca_certificate = data.vault_generic_secret.k8s_auth.data.CLUSTER_CA_CERTIFICATE
    token                  = data.vault_generic_secret.k8s_auth.data.k8s_sa_token
  }
}

provider "kubernetes" {
  # alias                  = "kubernetes"
  load_config_file       = false
  host                   = data.vault_generic_secret.k8s_auth.data.HOST
  cluster_ca_certificate = data.vault_generic_secret.k8s_auth.data.CLUSTER_CA_CERTIFICATE
  token                  = data.vault_generic_secret.k8s_auth.data.k8s_sa_token
}

locals{
  ns = "crypto"
}


resource "kubernetes_namespace" "ns" {
  metadata {
    name = local.ns
     labels = {
       istio-injection = "enabled"
     }
  }
}

resource "kubernetes_limit_range" "limit" {
  metadata {
    name = "default-limit-range"
    namespace = local.ns
  }
  spec {
    limit {
      type = "Container"
      default_request = {
        cpu    = "20m"
        memory = "50Mi"
      }
    }
  }
}
resource "kubernetes_limit_range" "limit2" {
  metadata {
    name = "default-limit-range2"
    namespace = local.ns
  }
  spec {
    limit {
      type = "Container"
      default = {
        cpu    = "500m"
        memory = "512Mi"
      }
    }
  }
}


data "vault_generic_secret" "gitlab_token" {
  path = "secret/gitlab"
}

resource "kubernetes_secret" "gitlab-token" {
  metadata {
    name      = "gitlab-token"
    namespace = local.ns
  }

  data = {
    "username" = data.vault_generic_secret.gitlab_token.data.username
    "password" = data.vault_generic_secret.gitlab_token.data.token_read_repo
  }
  depends_on = [kubernetes_namespace.ns]

}
