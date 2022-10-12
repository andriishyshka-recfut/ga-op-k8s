resource "kubernetes_manifest" "ingress_ip_whitelist" {
  for_each = local.ipWhiteList
  manifest = {
    "apiVersion" = "security.istio.io/v1beta1"
    "kind"       = "AuthorizationPolicy"
    "metadata" = {
      "name"      = "${each.key}-ip-whitelist"
      "namespace" = "istio-ingress"
    }
    "spec" = {
      "action" = "ALLOW"
      "rules" = [
        {
          "from" = [
            {
              "source" = {
                "ipBlocks" = each.value.iplist
              }
            },
          ]
        },
      ]
      "selector" = {
        "matchLabels" = {
          "istio" = each.value.ingress
        }
      }
    }
  }
}
