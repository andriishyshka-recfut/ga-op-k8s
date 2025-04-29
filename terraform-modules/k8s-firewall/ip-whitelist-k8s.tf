terraform {
  required_version = ">= 0.13"

  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
}

provider "kubectl" {
  host                   = var.k8s.HOST
  cluster_ca_certificate = var.k8s.CLUSTER_CA_CERTIFICATE
  token                  = var.k8s.API_KEY
  load_config_file       = false
}
# resource "kubernetes_manifest" "ingress_ip_whitelist" {
#   for_each = local.ipWhiteList
#   manifest = {
#     "apiVersion" = "security.istio.io/v1beta1"
#     "kind"       = "AuthorizationPolicy"
#     "metadata" = {
#       "name"      = "${each.key}-ip-whitelist"
#       "namespace" = "istio-ingress"
#     }
#     "spec" = {
#       "action" = "ALLOW"
#       "rules" = [
#         {
#           "from" = [
#             {
#               "source" = {
#                 "ipBlocks" = each.value.iplist
#               }
#             },
#           ]
#         },
#       ]
#       "selector" = {
#         "matchLabels" = {
#           "istio" = each.value.ingress
#         }
#       }
#     }
#   }
# }
resource "kubectl_manifest" "ingress_ip_whitelist" {
  for_each  = local.ipWhiteList
  yaml_body = templatefile("${path.module}/whitelist.tftpl", { settings = each.value, name = each.key })
}
