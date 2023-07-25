resource "helm_release" "tor-controller" {
  name       = "tor-controller"
  chart      = "tor-controller"
  repository = "https://bugfest.github.io/tor-controller"
  wait       = true
  atomic     = true
  namespace  = "tor-controller"
  version    = "0.1.11"
  timeout    = 900
}
