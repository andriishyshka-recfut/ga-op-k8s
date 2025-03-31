resource "helm_release" "cnpg" {
  name       = "cnpg"
  namespace  = local.namespace
  chart      = "cloudnative-pg"
  repository = "https://cloudnative-pg.github.io/charts"
  wait       = true
  atomic     = true
  version    = local.operator_version
  values = [
    "${file("${path.module}/cnpg-values.yaml")}"
  ]
}
