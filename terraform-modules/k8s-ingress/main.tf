resource "kubectl_manifest" "ingress_letsencrypt_cert" {
  for_each   = local.certManager
  yaml_body  = templatefile("${path.module}/letsencrypt.tftpl", merge({ values = each.value, name = each.key, }))
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

