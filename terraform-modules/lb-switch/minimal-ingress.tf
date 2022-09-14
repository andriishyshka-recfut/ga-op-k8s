resource "kubernetes_manifest" "vault_letsencrypt_cert" {
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "Certificate"
    "metadata" = {
      "name"      = "vault-cert"
      "namespace" = "istio-ingress"
      "annotations" = {
        "kubernetes.io/ingress.class" = "istio"
      }
    }
    "spec" = {
      "commonName" = local.VaultAddress
      "dnsNames" = [
        local.VaultAddress,
      ]
      "issuerRef" = {
        "kind" = "ClusterIssuer"
        "name" = "letsencrypt-prod"
      }
      "secretName" = "vault-cert"
    }
  }
}

resource "kubernetes_manifest" "vault_ingress_gateway" {
  manifest = {
    "apiVersion" = "networking.istio.io/v1beta1"
    "kind"       = "Gateway"
    "metadata" = {
      "name"      = "vault-wg-gateway"
      "namespace" = "istio-ingress"
    }
    "spec" = {
      "selector" = {
        "istio" = "ingressgateway"
      }
      "servers" = [
        # {
        #   "hosts" = [
        #     var.VaultAddress
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
            local.VaultAddress
          ]
          "port" = {
            "name"     = "https"
            "number"   = 443
            "protocol" = "HTTPS"
          }
          "tls" = {
            "credentialName" = "vault-cert"
            "mode"           = "SIMPLE"
          }
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "vault_ingress_virtualservice" {
  manifest = {
    "apiVersion" = "networking.istio.io/v1beta1"
    "kind"       = "VirtualService"
    "metadata" = {
      "name"      = "vault-virtualservice"
      "namespace" = "vault"
    }
    "spec" = {
      "gateways" = [
        "istio-ingress/vault-wg-gateway",
      ]
      "hosts" = [
        local.VaultAddress
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
                "host" = "vault-active"
                "port" = {
                  "number" = "8200"
                }
              }
            },
          ]
        },
      ]
    }
  }
}
