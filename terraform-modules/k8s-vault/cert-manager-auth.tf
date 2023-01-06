# resource "null_resource" "default_issuer_production_disable" {
#   provisioner "local-exec" {
#     command = <<-EOT
#       vault auth disable default-issuer-${var.Cluster}-${var.Color}
#     EOT
#     environment = {
#       VAULT_ADDR = "https://vault.p.regemini.io"
#     }
#   }
# }

# resource "vault_auth_backend" "default_issuer_production" {
#   type = "kubernetes"
#   path = "default-issuer-${var.Cluster}-${var.Color}"
#   tune {
#     max_lease_ttl = "2764800s"
#   }
#   depends_on = [
#     null_resource.default_issuer_production_disable
#   ]
# }

# resource "vault_kubernetes_auth_backend_config" "default_issuer_production" {
#   backend                = "default-issuer-${var.Cluster}-${var.Color}"
#   kubernetes_host        = data.vault_generic_secret.cluster_token.data["HOST"]
#   kubernetes_ca_cert     = data.kubernetes_secret.vault_sa.data["ca.crt"]
#   token_reviewer_jwt     = data.kubernetes_secret.vault_sa.data["token"]
#   issuer                 = "kubernetes/serviceaccount"
#   disable_local_ca_jwt   = "true"
#   disable_iss_validation = "true"
#   depends_on = [
#     vault_auth_backend.default_issuer_production
#   ]
# }

# resource "vault_kubernetes_auth_backend_role" "default_issuer_production" {
#   backend                          = "default-issuer-${var.Cluster}-${var.Color}"
#   role_name                        = "cert-manager-${var.Cluster}-${var.Color}"
#   bound_service_account_names      = ["vault"]
#   bound_service_account_namespaces = ["kube-system"]
#   token_ttl                        = 0
#   token_policies                   = ["pki"]
#   depends_on = [
#     vault_kubernetes_auth_backend_config.default_issuer_production
#   ]
# }

# resource "kubernetes_manifest" "vault_certmanager" {
#   manifest = {
#     "apiVersion" = "cert-manager.io/v1"
#     "kind"       = "ClusterIssuer"
#     "metadata" = {
#       "name" = "vault-issuer"
#     }
#     "spec" = {
#       "vault" = {
#         "auth" = {
#           "kubernetes" = {
#             "mountPath" = "/v1/auth/k8s-${var.Cluster}-${var.Color}"
#             "role"      = "cert-manager"
#             "secretRef" = {
#               "key"  = "token"
#               "name" = data.kubernetes_service_account.vault.default_secret_name
#             }
#           }
#         }
#         "path"   = "pki/sign/cert-manager"
#         "server" = var.VaultAddress
#       }
#     }
#   }
# }

data "kubernetes_service_account" "cert_manager" {
  metadata {
    name      = "${var.Cluster}-cert-manager"
    namespace = "kube-system"
  }
  depends_on = [
    kubernetes_secret_v1.cert_manager
  ]
}

resource "kubernetes_secret_v1" "cert_manager" {
  metadata {
    namespace = "kube-system"
    name = "sa-${var.Cluster}-cert-manager"
    annotations = {
      "kubernetes.io/service-account.name" = "${var.Cluster}-cert-manager"
    }
  }
  type = "kubernetes.io/service-account-token"
}

resource "helm_release" "vault_certmanager" {
  name      = "vault-issuer"
  chart     = "${path.module}/charts/vault_certmanager"
  namespace = "istio-ingress"
  wait      = true
  atomic    = true
  set {
    name  = "mountPath"
    value = "/v1/auth/k8s-${var.Cluster}-${var.Color}"
  }
  set {
    name  = "secretName"
    value = "sa-${var.Cluster}-cert-manager"
  }
  set {
    name  = "vaultAddress"
    value = var.VaultAddress
  }
  set {
    name  = "vaultRole"
    value = "cert-manager"
  }
  set {
    name  = "pkiRole"
    value = "elastic"
  }
  set {
    name  = "pkiPath"
    value = "pki-elastic-int"
  }
}
