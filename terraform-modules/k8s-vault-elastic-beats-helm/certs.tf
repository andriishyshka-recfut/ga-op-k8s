resource "kubectl_manifest" "vault_headless_issuer" {
  yaml_body = templatefile("${path.module}../../../templates/cert-manager/Issuer.tftpl", { values = local.headless_cert })
}

resource "kubernetes_manifest" "certificate_elastic_headless" {
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "Certificate"
    "metadata" = {
      "name"      = "elastic-headless-certs"
      "namespace" = var.ElasticSettings.globalSettings.namespace
    }
    "spec" = {
      "commonName" = "*.red-coor-headless.elastic.svc"
      "dnsNames" = [
        "*.red-coor-headless.elastic.svc.cluster.local"
      ]
      "issuerRef" = {
        "kind" = "Issuer"
        "name" = "elastic-headless"
      }
      "secretName" = "elastic-headless-certs"
      "duration" = "720h"
    }
  }
  depends_on = [ kubectl_manifest.vault_headless_issuer ]
}