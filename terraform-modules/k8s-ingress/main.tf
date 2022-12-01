resource "kubernetes_manifest" "ingress_letsencrypt_cert" {
  for_each = local.certManager
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

resource "kubernetes_manifest" "ingress_gateway_tls" {
  for_each = local.ingressTls
  manifest = {
    "apiVersion" = "networking.istio.io/v1beta1"
    "kind"       = "Gateway"
    "metadata" = {
      "name"      = lookup(each.value, "ingressgateway", false) != false ? "${each.key}-${split("-", each.value.ingressgateway)[1]}-gateway" : "${each.key}-wg-gateway"
      "namespace" = "istio-ingress"
    }
    "spec" = {
      "selector" = {
        "istio" = lookup(each.value, "ingressgateway", "ingressgateway")
      }
      "servers" = [
        {
          "hosts" = each.value.domain
          "port" = {
            "name"     = "http"
            "number"   = 80
            "protocol" = "HTTP"
          }
          "tls" = {
            "httpsRedirect" = "true"
          }
        },
        {
          "hosts" = each.value.domain
          "port" = {
            "name"     = "https"
            "number"   = 443
            "protocol" = "HTTPS"
          }
          "tls" = {
            "credentialName" = lookup(each.value, "cert-name", "${each.key}-cert")
            "mode"           = "SIMPLE"
          }
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "ingress_gateway_wo_tls" {
  for_each = local.ingressWoTls
  manifest = {
    "apiVersion" = "networking.istio.io/v1beta1"
    "kind"       = "Gateway"
    "metadata" = {
      "name"      = lookup(each.value, "ingressgateway", false) != false ? "${each.key}-${split("-", each.value.ingressgateway)[1]}-gateway" : "${each.key}-wg-gateway"
      "namespace" = "istio-ingress"
    }
    "spec" = {
      "selector" = {
        "istio" = lookup(each.value, "ingressgateway", "ingressgateway")
      }
      "servers" = [
        {
          "hosts" = each.value.domain
          "port" = {
            "name"     = "https"
            "number"   = 443
            "protocol" = "HTTPS"
          }
          "tls" = {
            "credentialName" = lookup(each.value, "cert-name", "${each.key}-cert")
            "mode"           = "SIMPLE"
          }
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "ingress_virtualservice" {
  for_each = local.ingressSettings
  manifest = lookup(each.value, "redirect_url", false) == false ? {
    "apiVersion" = "networking.istio.io/v1beta1"
    "kind"       = "VirtualService"
    "metadata"   = {
      "name"      = "${each.key}-virtualservice"
      "namespace" = each.value.namespace
    }
    "spec" = {
      "gateways" = [
        lookup(each.value, "ingressgateway", false) != false ? "istio-ingress/${each.key}-${split("-", each.value.ingressgateway)[1]}-gateway" : "istio-ingress/${each.key}-wg-gateway",
      ]
      "hosts" = each.value.domain
      "http"  = [
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
  } : {
    "apiVersion" = "networking.istio.io/v1beta1"
    "kind"       = "VirtualService"
    "metadata"   = {
      "name"      = "${each.key}-virtualservice"
      "namespace" = each.value.namespace
    }
    "spec" = {
      "gateways" = [
        lookup(each.value, "ingressgateway", false) != false ? "istio-ingress/${each.key}-${split("-", each.value.ingressgateway)[1]}-gateway" : "istio-ingress/${each.key}-wg-gateway",
      ]
      "hosts" = each.value.domain
      "http"  = [
        {
          "match" = [
            {
              "uri" = {
                "prefix" = "/"
              }
            },
          ]
          "redirect" = {
            "authority" = each.value.redirect_url
            "port" = lookup(each.value, "port", 443)
            "scheme" = lookup(each.value, "port", 443) == 443 ? "https" : "http"
            }
        },
      ]
    }
  }
