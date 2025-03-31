resource "helm_release" "kyverno" {
  repository = "https://kyverno.github.io/kyverno/"
  chart      = "kyverno"
  name       = "kyverno"
  version    = local.version
  namespace  = local.namespace
  values = [
    file("${path.module}/kyverno-values.yaml")
  ]
}
