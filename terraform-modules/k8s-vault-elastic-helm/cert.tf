resource "kubernetes_manifest" "certificate_elastic_es_cert" {
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "Certificate"
    "metadata" = {
      "name"      = "${local.globalSettings.clusterName}-coor"
      "namespace" = local.globalSettings.namespace
    }
    "spec" = {
      "commonName" = "${local.globalSettings.clusterName}-coor"
      "dnsNames" = [
        "${local.globalSettings.clusterName}-coor",
        "${local.globalSettings.clusterName}-coor.${local.globalSettings.namespace}.svc",
      ]
      "issuerRef" = {
        "kind" = "ClusterIssuer"
        "name" = "vault-issuer"
      }
      "secretName" = "elastic-https-certs"
    }
  }
}


# resource "kubernetes_manifest" "issuer_my_issuer" {
#   manifest = {
#     "apiVersion" = "cert-manager.io/v1"
#     "kind"       = "Issuer"
#     "metadata" = {
#       "name"      = "elastic"
#       "namespace" = local.globalSettings.namespace
#     }
#     "spec" = {
#       "selfSigned" = {}
#     }
#   }
# }

# resource "kubernetes_manifest" "certificate_my_ca_cert" {
#   manifest = {
#     "apiVersion" = "cert-manager.io/v1"
#     "kind"       = "Certificate"
#     "metadata" = {
#       "name"      = "elastic-transport-ca"
#       "namespace" = local.globalSettings.namespace
#     }
#     "spec" = {
#       "commonName" = "elastic-transport-internal"
#       "isCA"       = true
#       "issuerRef" = {
#         "kind" = "Issuer"
#         "name" = "elastic"
#       }
#       "secretName" = "elastic-transport-certs"
#       "subject" = {
#         "organizations" = [
#           "Gemini Advisory",
#         ]
#       }
#     }
#   }
# }


resource "kubernetes_manifest" "clusterissuer_vault_elastic_transport" {
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind" = "ClusterIssuer"
    "metadata" = {
      "name" = "vault-elastic-transport"
    }
    "spec" = {
      "vault" = {
        "auth" = {
          "kubernetes" = {
            "mountPath" = "/v1/auth/k8s-${var.Cluster}-${var.Color}"
            "role" = "cert-manager"
            "secretRef" = {
              "key" = "token"
              "name" = "sa-${var.Cluster}-cert-manager"
            }
          }
        }
        "path" = "pki-elastic-int/sign/transport"
        "server" = var.VaultAddress
      }
    }
  }
}

resource "kubernetes_manifest" "certificate_elastic_elastic_transport_certs" {
  for_each = toset(local.globalSettings.transport.certs)
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind" = "Certificate"
    "metadata" = {
      "name" = "elastic-transport-certs-${each.key}"
      "namespace" = local.globalSettings.namespace
    }
    "spec" = {
      "commonName" = "elasticsearch-coor.elastic.svc"
      "dnsNames" = [
        "elasticsearch-coor.elastic.svc",
        "elasticsearch-coor.elastic.svc.cluster.local",
        "*.elasticsearch-coor.elastic.svc",
        "*.elasticsearch-coor.elastic.svc.cluster.local",
        "elasticsearch-master.elastic.svc",
        "elasticsearch-master.elastic.svc.cluster.local",
        "*.elasticsearch-master.elastic.svc",
        "*.elasticsearch-master.elastic.svc.cluster.local",
        "elasticsearch-data.elastic.svc",
        "elasticsearch-data.elastic.svc.cluster.local",
        "*.elasticsearch-data.elastic.svc",
        "*.elasticsearch-data.elastic.svc.cluster.local",
        "elasticsearch-ingest.elastic.svc",
        "elasticsearch-ingest.elastic.svc.cluster.local",
        "*.elasticsearch-ingest.elastic.svc",
        "*.elasticsearch-ingest.elastic.svc.cluster.local",
      ]
      "duration" = "${local.globalSettings.transport.duration}"
      "issuerRef" = {
        "kind" = "ClusterIssuer"
        "name" = "vault-elastic-transport"
      }
      "privateKey" = {
        "algorithm" = "RSA"
        "size" = 2048
      }
      "renewBefore" = "48h"
      "secretName" = "elastic-transport-certs-${each.key}"
    }
  }
}