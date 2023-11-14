
resource "helm_release" "reloader" {
  count = local.installCount
  name       = "reloader"
  chart      = "reloader"
  repository = "https://stakater.github.io/stakater-charts"
  namespace  = local.camelNs
  wait       = true
  atomic     = true
}
