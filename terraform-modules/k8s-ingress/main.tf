resource "kubernetes_manifest" "ingress_letsencrypt_cert" {
  for_each = local.ingressSettings
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "Certificate"
    "metadata" = {
      "name"      = "${each.key}-cert"
      "namespace" = "istio-ingress"
      "annotations" = {
        "kubernetes.io/ingress.class" = "istio"
      }
    }
    "spec" = {
      "commonName" = each.value.domain
      "dnsNames" = [
        each.value.domain,
      ]
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
  manifest = {
    "apiVersion" = "networking.istio.io/v1beta1"
    "kind"       = "Gateway"
    "metadata" = {
      "name"      = "${each.key}-wg-gateway"
      "namespace" = "istio-ingress"
    }
    "spec" = {
      "selector" = {
        "istio" = "ingressgateway"
      }
      "servers" = [
        # {
        #   "hosts" = [
        #     each.value.domain
        #   ]
        #   "port" = {
        #     "name"     = "http"
        #     "number"   = 80
        #     "protocol" = "HTTP"
        #   }
        #   "tls" = {
        #     "httpsRedirect" = "true"
        #   }
        # },
        {
          "hosts" = [
            each.value.domain
          ]
          "port" = {
            "name"     = "https"
            "number"   = 443
            "protocol" = "HTTPS"
          }
          "tls" = {
            "credentialName" = lookup(var.Settings.clusters[var.Cluster].ingress[each.key], "cert-name", "${each.key}-cert")
            "mode"           = "SIMPLE"
          }
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "ingress_virtualservice" {
  for_each = local.certManager
  manifest = {
    "apiVersion" = "networking.istio.io/v1beta1"
    "kind"       = "VirtualService"
    "metadata" = {
      "name"      = "${each.key}-virtualservice"
      "namespace" = each.value.namespace
    }
    "spec" = {
      "gateways" = [
        "istio-ingress/${each.key}-wg-gateway",
      ]
      "hosts" = [
        each.value.domain
      ]
      "http" = [
        {
          "match" = [
            {
              "uri" = {
                "prefix" = "/"
              }
            },
          ]
          "route" = [
            {
              "destination" = {
                "host" = each.value.service
                "port" = {
                  "number" = each.value.port
                }
              }
            },
          ]
        },
      ]
    }
  }
}
