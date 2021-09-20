
resource "helm_release" "etcd" {
  name       = "etcd"
  chart      = "etcd"
  repository = "https://charts.bitnami.com/bitnami"
  #version           = "0.1.0"
  namespace         = local.minioNs
  dependency_update = "true"

  set {
    name  = "persistence.size"
    value = "1Gi"
  }
  set {
    name  = "auth.rbac.enabled"
    value = "false"
  }
  set {
    name = "nodeSelector.workloadsType"
    value = "data"
  }
  set {
    name = "tolerations[0].key"
    value = "workloadsType"
  }
  set {
    name = "tolerations[0].operator"
    value = "Exists"
  }
  set {
    name = "tolerations[0].effect"
    value = "NoSchedule"
  }
  set {
    name = "podAnnotations.sidecar\\.istio\\.io/inject"
    value = " false"
  }
}
