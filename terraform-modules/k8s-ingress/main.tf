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

# resource "kubernetes_manifest" "ingress_letsencrypt_cert" {
#   for_each  = local.certManager
#   manifest = yamldecode(templatefile("${path.module}/letsencrypt.tftpl", merge({ domains = each.value.domain }, { name = each.key })))
#   depends_on = [ kubectl_manifest.ingress_virtualservice ]
# }

# resource "kubernetes_manifest" "ingress_gateway" {
#   for_each = local.ingressSettings
#   manifest = yamldecode(templatefile("${path.module}/gateway.tftpl", merge({ settings = each.value }, { name = each.key })))
# }
# resource "kubernetes_manifest" "ingress_virtualservice" {
#   for_each = local.virtualService
#   manifest = yamldecode(templatefile("${path.module}/virtualservice.tftpl", merge({ settings = local.ingressSettings[each.value.ingress] }, { service = local.ingressSettings[each.value.ingress].services[each.value.index], name = each.key, ingress = each.value.ingress, basic_auth = local.auth_user_list })))
#   depends_on = [ kubernetes_manifest.ingress_gateway ]
# }

# resource "kubernetes_manifest" "ingress_internal" {
#   for_each = local.internalIngressSettings
#   manifest = yamldecode(templatefile("${path.module}/internal-ingress.tftpl", merge({ settings = each.value }, { name = each.key }, { static_ip = local.internalStaticIps[each.key] })))
# }

resource "kubectl_manifest" "ingress_letsencrypt_cert" {
  for_each   = local.certManager
  yaml_body  = templatefile("${path.module}/letsencrypt.tftpl", merge({ domains = each.value.domain }, { name = each.key }))
  depends_on = [kubectl_manifest.ingress_virtualservice]
}

resource "kubectl_manifest" "ingress_gateway" {
  for_each  = local.ingressSettings
  yaml_body = templatefile("${path.module}/gateway.tftpl", merge({ settings = each.value }, { name = each.key }))
}

resource "kubectl_manifest" "ingress_virtualservice" {
  for_each  = local.virtualService
  yaml_body = templatefile("${path.module}/virtualservice.tftpl", merge({ settings = local.ingressSettings[each.value.ingress] }, { service = local.ingressSettings[each.value.ingress].services[each.value.index], name = each.key, ingress = each.value.ingress, basic_auth = local.auth_user_list }))
  depends_on = [
    kubectl_manifest.ingress_gateway
  ]
}

resource "kubectl_manifest" "ingress_internal" {
  for_each  = local.internalIngressSettings
  yaml_body = templatefile("${path.module}/internal-ingress.tftpl", merge({ settings = each.value }, { name = each.key }, { static_ip = local.internalStaticIps[each.key] }))
}
