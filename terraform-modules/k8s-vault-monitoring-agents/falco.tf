resource "helm_release" "falco" {
  name       = "falco"
  chart      = "falco"
  repository = "https://falcosecurity.github.io/charts"
  wait       = true
  atomic     = true
  namespace  = local.beatsValues.namespace
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
  set {
    name  = "resources.requests.cpu"
    value = "10m"
  }
  set {
    name  = "resources.requests.memory"
    value = "300Mi"
  }
  # https://github.com/falcosecurity/falco/issues/669
  set {
    name  = "falco.syscallEventDrops.actions[0]"
    value = "ignore"
  }
  set {
    name  = "tolerations[0].effect"
    value = "NoSchedule"
  }
  set {
    name  = "tolerations[0].key"
    value = "workloadsType"
  }
  set {
    name  = "tolerations[0].operator"
    value = "Exists"
  }
}
