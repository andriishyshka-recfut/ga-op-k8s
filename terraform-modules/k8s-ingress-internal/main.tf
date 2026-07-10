resource "kubectl_manifest" "ingress_internal" {
  for_each  = local.ingresses
  yaml_body = templatefile("${path.module}/internal-ingress.tftpl", merge({ settings = each.value }, { name = each.key }, { static_ip = try(local.internalStaticIps[lookup(each.value, "ip_link", each.key)], local.internalStaticIps[each.key]) }))
}

resource "kubectl_manifest" "endpoints" {
  for_each  = local.services
  yaml_body = templatefile("${path.module}/endpoint.tftpl", merge({ settings = each.value }, { name = each.key }, { static_ip = lookup(each.value, "ip", try(local.internalStaticIps[lookup(each.value, "ip_link", each.key)].ip, local.internalStaticIps[each.key].ip, null)) }))
}

resource "kubectl_manifest" "service_internal" {
  for_each   = local.services
  yaml_body  = templatefile("${path.module}/internal-service.tftpl", merge({ settings = each.value }, { name = each.key }))
  depends_on = [kubectl_manifest.endpoints]
}
