resource "helm_release" "kyverno" {
  repository = "https://kyverno.github.io/kyverno/"
  chart      = "kyverno"
  name       = "kyverno"
  version    = local.version
  namespace  = local.namespace
  set {
    name  = "admissionController.replicas"
    value = 3
  }
  set {
    name  = "backgroundController.replicas"
    value = 2
  }
  set {
    name  = "cleanupController.replicas"
    value = 2
  }
  set {
    name  = "reportsController.replicas"
    value = 2
  }
}
