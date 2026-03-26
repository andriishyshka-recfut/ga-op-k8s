resource "helm_release" "tor-controller" {
  name       = "tor-controller"
  chart      = "tor-controller"
  repository = "https://bugfest.github.io/tor-controller"
  wait       = true
  atomic     = true
  namespace  = "tor-controller"
  version    = "0.1.17"
  timeout    = 900

  set = [
    {
      name  = "kubeRbacProxy.image.repository"
      value = "bitnami/kube-rbac-proxy"
    },
    {
      name  = "kubeRbacProxy.image.tag"
      value = "latest"
    }
  ]

}
