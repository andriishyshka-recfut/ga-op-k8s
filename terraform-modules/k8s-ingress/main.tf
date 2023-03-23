resource "kubernetes_manifest" "ingress_letsencrypt_cert" {
  for_each = local.certManager
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "Certificate"
    "metadata" = {
      "name"      = "${each.key}-cert"
      "namespace" = "istio-ingress"
      "annotations" = {
        "kubernetes.io/ingress.class"                 = "istio"
        "cert-manager.io/issue-temporary-certificate" = "${each.value.cert-manager}"
      }
    }
    "spec" = {
      "commonName" = each.value.domain[0]
      "dnsNames"   = each.value.domain
      "issuerRef" = {
        "kind" = "ClusterIssuer"
        "name" = "letsencrypt-prod"
      }
      "secretName" = "${each.key}-cert"
    }
  }
}

resource "kubernetes_manifest" "ingress_gateway" {
  for_each = local.ingressSettings
  manifest = yamldecode(templatefile("${path.module}/gateway.tftpl", merge({ settings = each.value }, { name = each.key })))
  depends_on = [
    kubernetes_manifest.ingress_letsencrypt_cert
  ]
}
resource "kubernetes_manifest" "ingress_virtualservice" {
  for_each = local.virtualService
  manifest = yamldecode(templatefile("${path.module}/virtualservice.tftpl", merge({ settings = local.ingressSettings[each.value.ingress] }, { service = local.ingressSettings[each.value.ingress].services[each.value.index], name = each.key, ingress = each.value.ingress })))
  depends_on = [
    kubernetes_manifest.ingress_letsencrypt_cert
  ]
}
