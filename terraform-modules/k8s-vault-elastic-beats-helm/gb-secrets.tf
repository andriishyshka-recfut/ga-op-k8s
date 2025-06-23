data "vault_pki_secret_backend_issuer" "green_blue_mon" {
  backend    = "/pki-elastic-int"
  issuer_ref = "default"
}

resource "kubernetes_secret" "mon_ca" {
  metadata {
    name      = "mon-ca-cert"
    namespace = "monitoring"
  }
  data = {
    "ca.crt" = data.vault_pki_secret_backend_issuer.green_blue_mon.certificate
  }
  depends_on = [data.vault_pki_secret_backend_issuer.green_blue_mon]
}

resource "kubectl_manifest" "external_secrets_store" {
  yaml_body = templatefile("${path.module}/templates/crd/SecretStore.tftpl", {})
}

resource "kubectl_manifest" "mon_external_secrets_elastic" {
  yaml_body  = templatefile("${path.module}/templates/crd/ExternalSecret.tftpl", {})
  depends_on = [kubectl_manifest.external_secrets_store]
}
# resource "kubernetes_manifest" "external_secrets_store" {
#   manifest = {
#     "apiVersion" = "external-secrets.io/v1alpha1"
#     "kind"       = "SecretStore"
#     "metadata" = {
#       "name"      = "vault-backend"
#       "namespace" = "monitoring"
#     }
#     "spec" = {
#       "provider" = {
#         "vault" = {
#           "auth" = {
#             "kubernetes" = {
#               "mountPath" = "k8s-production-red"
#               "role"      = "external-secrets"
#             }
#           }
#           "server"  = "https://vault.p.regemini.io"
#           "version" = "v2"
#         }
#       }
#     }
#   }
# }

# resource "kubernetes_manifest" "mon_external_secrets_elastic" {
#   manifest = {
#     "apiVersion" = "external-secrets.io/v1beta1"
#     "kind"       = "ExternalSecret"
#     "metadata" = {
#       "name" = "mon-elastic-creds"
#       "namespace" : "monitoring"
#     }
#     "spec" = {
#       "target" = {
#         "name" = "mon-elastic-creds"
#         "template" = {
#           "data" = {
#             "elastic" = "{{ .password }}"
#           }
#         }
#       }
#       "dataFrom" = [
#         {
#           "extract" = {
#             "key" = "secret/data/mw/elastic/mon"
#           }
#         },
#       ]
#       "refreshInterval" = "1h"
#       "secretStoreRef" = {
#         "kind" = "SecretStore"
#         "name" = "vault-backend"
#       }
#     }
#   }
#   depends_on = [kubernetes_manifest.external_secrets_store]

# }

resource "kubernetes_service" "mon_service" {
  metadata {
    name      = "mon-es-http"
    namespace = "monitoring"
  }
  spec {
    cluster_ip       = "None"
    session_affinity = "None"
    port {
      name        = "elastic"
      protocol    = "TCP"
      port        = 9222
      target_port = 9222
    }
  }
}

resource "kubernetes_endpoints" "mon_endpoint" {
  metadata {
    name      = "mon-es-http"
    namespace = "monitoring"
    labels = {
      "kubernetes.io/service-name" = "mon-es-http"
    }
  }

  subset {
    address {
      ip = "10.203.0.2"
    }

    port {
      name     = "elastic"
      port     = 9222
      protocol = "TCP"
    }
  }
}


resource "kubernetes_service" "mon_kibana_service" {
  metadata {
    name      = "kibana-kb-http"
    namespace = "monitoring"
  }
  spec {
    cluster_ip       = "None"
    session_affinity = "None"
    port {
      name        = "kibana"
      protocol    = "TCP"
      port        = 5602
      target_port = 5602
    }
  }
}

resource "kubernetes_endpoints" "mon_kibana_endpoint" {
  metadata {
    name      = "kibana-kb-http"
    namespace = "monitoring"
    labels = {
      "kubernetes.io/service-name" = "kibana-kb-http"
    }
  }

  subset {
    address {
      ip = "10.203.0.5"
    }

    port {
      name     = "kibana"
      port     = 5602
      protocol = "TCP"
    }
  }
}
