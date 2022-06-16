resource "kubernetes_manifest" "ingress_harbor_letsencrypt_cert" {
  count = local.harbor
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "Certificate"
    "metadata" = {
      "name"      = "harbor-cert"
      "namespace" = "istio-ingress"
    }
    "spec" = {
      "commonName" = "harbor.t.regemini.io"
      "dnsNames" = [
        "harbor.t.regemini.io",
      ]
      "issuerRef" = {
        "kind" = "ClusterIssuer"
        "name" = "letsencrypt-prod"
      }
      "secretName" = "harbor-cert"
    }
  }
}

resource "kubernetes_manifest" "ingress_harbor_gateway" {
  count = local.harbor
  manifest = {
    "apiVersion" = "networking.istio.io/v1beta1"
    "kind"       = "Gateway"
    "metadata" = {
      "name"      = "harbor-wg-gateway"
      "namespace" = "istio-ingress"
    }
    "spec" = {
      "selector" = {
        "istio" = "ingressgateway"
      }
      "servers" = [
        # {
        #   "hosts" = [
        #     "harbor.t.regemini.io"
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
            "harbor.t.regemini.io"
          ]
          "port" = {
            "name"     = "https"
            "number"   = 443
            "protocol" = "HTTPS"
          }
          "tls" = {
            "credentialName" = "harbor-cert"
            "mode"           = "SIMPLE"
          }
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "ingress_harbor_virtualservice" {
  count = local.harbor
  manifest = {
    "apiVersion" = "networking.istio.io/v1beta1"
    "kind"       = "VirtualService"
    "metadata" = {
      "name"      = "harbor-virtualservice"
      "namespace" = "harbor"
    }
    "spec" = {
      "gateways" = [
        "istio-ingress/harbor-wg-gateway",
      ]
      "hosts" = [
        "harbor.t.regemini.io"
      ]
      "http" = [
        {
          "match" = [
            {
              "uri" = {
                "prefix" = "/api/"
              }
            },
            {
              "uri" = {
                "prefix" = "/service/"
              }
            },
            {
              "uri" = {
                "prefix" = "/v2/"
              }
            },
            {
              "uri" = {
                "prefix" = "/c/"
              }
            },
            {
              "uri" = {
                "prefix" = "/chartrepo/"
              }
            },
          ]
          "route" = [
            {
              "destination" = {
                "host" = "harbor-core"
                "port" = {
                  "number" = 80
                }
              }
            },
          ]
        },
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
                "host" = "harbor-portal"
                "port" = {
                  "number" = 80
                }
              }
            },
          ]
        },
      ]
    }
  }
}
