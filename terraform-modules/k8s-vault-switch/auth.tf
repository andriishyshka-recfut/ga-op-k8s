
data "vault_generic_secret" "cluster_token" {
  path = "secret/kubernetes-production-blue"
}

data "kubernetes_service_account" "cert_manager" {
  metadata {
    name      = "production-cert-manager"
    namespace = "kube-system"
  }
}

data "kubernetes_secret" "cert_manager" {
  metadata {
    name      = data.kubernetes_service_account.cert_manager.default_secret_name
    namespace = "kube-system"
  }
}


resource "vault_auth_backend" "default_issuer_production" {
  type = "kubernetes"
  path = "default-issuer-production-blue"
  tune {
    max_lease_ttl = "2764800s"
  }
}

resource "vault_kubernetes_auth_backend_config" "default_issuer_production" {
  backend         = "default-issuer-production-blue"
  kubernetes_host = vault_generic_secret.cluster_token.data["HOST"]
}

resource "vault_kubernetes_auth_backend_role" "default_issuer_production" {
  backend                          = "default-issuer-production-blue"
  role_name                        = "cert-manager-production-blue"
  bound_service_account_names      = ["production-cert-manager"]
  bound_service_account_namespaces = ["kube-system"]
  token_ttl                        = 0
  token_policies                   = ["pki"]
}

resource "kubernetes_manifest" "vault_certmanager" {
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "ClusterIssuer"
    "metadata" = {
      "name" = "vault-issuer"
    }
    "spec" = {
      "vault" = {
        "auth" = {
          "kubernetes" = {
            "mountPath" = "/v1/auth/default-issuer-production-blue"
            "role"      = "cert-manager-production-blue"
            "secretRef" = {
              "key"  = "token"
              "name" = data.kubernetes_service_account.cert_manager.default_secret_name
            }
          }
        }
        "path"   = "pki/sign/cert-manager-production-blue"
        "server" = "https://vault.p.regemini.io"
      }
    }
  }
}
