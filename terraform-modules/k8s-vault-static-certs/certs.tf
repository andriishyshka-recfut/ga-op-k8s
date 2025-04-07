resource "kubernetes_secret" "certs" {
  for_each = local.certs

  metadata {
    name      = "${replace(each.key, ".", "-")}-cert"
    namespace = "istio-ingress"
  }

  data = {
    "tls.crt" = "${each.value.cert}\n${lookup(each.value, "intermediate", "")}"
    "tls.key" = "${each.value.key}"
  }

  type = "kubernetes.io/tls"
}

