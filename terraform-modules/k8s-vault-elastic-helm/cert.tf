resource "kubernetes_manifest" "certificate_elastic_es_cert" {
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "Certificate"
    "metadata" = {
      "name"      = "${local.globalSettings.clusterName}-coor"
      "namespace" = local.globalSettings.namespace
    }
    "spec" = {
      "commonName" = "${local.globalSettings.clusterName}-coor.${local.globalSettings.namespace}.svc.cluster.local"
      "dnsNames" = [
        #        "${local.globalSettings.clusterName}-coor",
        "${local.globalSettings.clusterName}-coor.${local.globalSettings.namespace}.svc.cluster.local",
      ]
      "issuerRef" = {
        "kind" = "Issuer"
        "name" = "vault-elastic"
      }
      "secretName" = "elastic-https-certs"
    }
  }
}

locals {
  certificates = toset(["elastic", "transport"])
  certIssuerValues = {
    namespace  = local.globalSettings.namespace
    vault_addr = var.Cluster == "sandbox" ? "https://vault.t.regemini.io" : "https://vault.p.regemini.io"
    pki = {
      name = "pki-elastic-int"
    }
    kube_auth = {
      role = "elastic"
    }
    cluster = var.Cluster
    color   = var.Color
  }
}

resource "kubectl_manifest" "vault_issuer" {
  for_each  = local.certificates
  yaml_body = templatefile("${path.module}../../../templates/cert-manager/Issuer.tftpl", { values = merge(local.certIssuerValues, { pki = { role = each.value , name = local.certIssuerValues.pki.name}, name = "vault-${each.value}", kube_auth = { role = local.globalSettings.namespace} }) })
}

# resource "kubernetes_manifest" "clusterissuer_vault_elastic_transport" {
#   manifest = {
#     "apiVersion" = "cert-manager.io/v1"
#     "kind"       = "ClusterIssuer"
#     "metadata" = {
#       "name" = "vault-elastic-transport"
#     }
#     "spec" = {
#       "vault" = {
#         "auth" = {
#           "kubernetes" = {
#             "mountPath" = "/v1/auth/k8s-${var.Cluster}-${var.Color}"
#             "role"      = "cert-manager"
#             "secretRef" = {
#               "key"  = "token"
#               "name" = "sa-${var.Cluster}-cert-manager"
#             }
#           }
#         }
#         "path"   = "pki-elastic-int/sign/transport"
#         "server" = var.VaultAddress
#       }
#     }
#   }
# }

resource "kubernetes_manifest" "certificate_elastic_elastic_transport_certs" {
  for_each = toset(local.globalSettings.transport.certs)
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "Certificate"
    "metadata" = {
      "name"      = "elastic-transport-certs-${each.key}"
      "namespace" = local.globalSettings.namespace
    }
    "spec" = {
      "commonName" = "${local.globalSettings.clusterName}-coor.elastic.svc.cluster.local"
      "dnsNames" = [
        #        "${local.globalSettings.clusterName}-coor.elastic.svc",
        "${local.globalSettings.clusterName}-coor.${local.globalSettings.namespace}.svc.cluster.local",
        #        "*.${local.globalSettings.clusterName}-coor.elastic.svc",
        "*.${local.globalSettings.clusterName}-coor.${local.globalSettings.namespace}.svc.cluster.local",
        #        "${local.globalSettings.clusterName}-master.elastic.svc",
        "${local.globalSettings.clusterName}-master.${local.globalSettings.namespace}.svc.cluster.local",
        #        "*.${local.globalSettings.clusterName}-master.elastic.svc",
        "*.${local.globalSettings.clusterName}-master.${local.globalSettings.namespace}.svc.cluster.local",
        #        "${local.globalSettings.clusterName}-data.elastic.svc",
        "${local.globalSettings.clusterName}-data.${local.globalSettings.namespace}.svc.cluster.local",
        #        "*.${local.globalSettings.clusterName}-data.elastic.svc",
        "*.${local.globalSettings.clusterName}-data.${local.globalSettings.namespace}.svc.cluster.local",
        #        "${local.globalSettings.clusterName}-ingest.elastic.svc",
        "${local.globalSettings.clusterName}-ingest.${local.globalSettings.namespace}.svc.cluster.local",
        #        "*.${local.globalSettings.clusterName}-ingest.elastic.svc",
        "*.${local.globalSettings.clusterName}-ingest.${local.globalSettings.namespace}.svc.cluster.local",
      ]
      "duration" = "${local.globalSettings.transport.duration}"
      "issuerRef" = {
        "kind" = "Issuer"
        "name" = "vault-transport"
      }
      "privateKey" = {
        "algorithm" = "RSA"
        "size"      = 2048
      }
      "renewBefore" = "48h"
      "secretName"  = "elastic-transport-certs-${each.key}"
    }
  }
}
