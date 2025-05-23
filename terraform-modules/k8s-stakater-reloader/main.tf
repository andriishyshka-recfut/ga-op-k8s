resource "helm_release" "stakater" {
  name         = "stakater"
  namespace    = local.namespace
  repository   = "https://stakater.github.io/stakater-charts"
  chart        = "reloader"
  wait         = true
  atomic       = true
  version      = local.chartVersion
  values = [
    templatefile("${path.module}/stakater.tftpl", { appVersion = local.appVersion })
  ]
}
