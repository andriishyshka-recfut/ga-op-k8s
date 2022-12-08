resource "kubernetes_manifest" "certificate_elastic_es_cert" {
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "Certificate"
    "metadata" = {
      "name"      = "${local.globalSettings.clusterName}-es-cert"
      "namespace" = local.globalSettings.namespace
    }
    "spec" = {
      "commonName" = "${local.globalSettings.clusterName}-es-http"
      "dnsNames" = [
        "${local.globalSettings.clusterName}-es-http",
        "${local.globalSettings.clusterName}-es-http.${local.globalSettings.namespace}.svc",
      ]
      "issuerRef" = {
        "kind" = "ClusterIssuer"
        "name" = "vault-issuer"
      }
      "secretName" = "elastic-https-certs"
    }
  }
}


resource "kubernetes_manifest" "issuer_my_issuer" {
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "Issuer"
    "metadata" = {
      "name"      = "elastic"
      "namespace" = local.globalSettings.namespace
    }
    "spec" = {
      "selfSigned" = {}
    }
  }
}

resource "kubernetes_manifest" "certificate_my_ca_cert" {
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "Certificate"
    "metadata" = {
      "name"      = "elastic-transport-ca"
      "namespace" = local.globalSettings.namespace
    }
    "spec" = {
      "commonName" = "elastic-transport-internal"
      "isCA"       = true
      "issuerRef" = {
        "kind" = "Issuer"
        "name" = "elastic"
      }
      "secretName" = "elastic-transport-certs"
      "subject" = {
        "organizations" = [
          "Gemini Advisory",
        ]
      }
    }
  }
}
