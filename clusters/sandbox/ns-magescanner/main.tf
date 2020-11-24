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

locals {
  ns = "magescanner"
}

resource "kubernetes_namespace" "ns" {
  metadata {
    name = local.ns
    labels = {
      istio-injection = "enabled"
    }
  }
}

resource "kubernetes_persistent_volume_claim" "geoip-magescanner" {
  metadata {
    name      = "geoip-magescanner"
    namespace = local.ns
  }
  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "standard"
    resources {
      requests = {
        storage = "2Gi"
      }
    }
  }
}

resource "kubernetes_limit_range" "limit" {
  metadata {
    name      = "default-limit-range"
    namespace = local.ns
  }
  spec {
    limit {
      type = "Container"
      default_request = {
        cpu    = "10m"
        memory = "50Mi"
      }
      default = {
        cpu    = "200m"
        memory = "300Mi"
      }
    }
  }
}

resource "kubernetes_role_binding" "developers" {
  metadata {
    name      = "developers"
    namespace = local.ns
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "admin"
  }
  subject {
    kind      = "User"
    name      = "nikita.leonov@geminiadvisory.io"
    api_group = "rbac.authorization.k8s.io"

  }
}
