resource "helm_release" "falco" {
  name       = "falco"
  chart      = "falco"
  repository = "https://falcosecurity.github.io/charts"
  wait       = true
  atomic     = true
  namespace  = local.es_values.namespace
  set {
    name  = "podSecurityPolicy.create"
    value = "true"
  }
  set {
    name  = "ebpf.enabled"
    value = "true"
  }
  set {
    name  = "falco.jsonOutput"
    value = "true"
  }
  set {
    name  = "auditLog.enabled"
    value = "true"
  }
}
