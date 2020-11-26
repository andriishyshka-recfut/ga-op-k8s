
resource "helm_release" "etcd" {
  name       = "etcd"
  chart      = "etcd"
  repository = "https://charts.bitnami.com/bitnami"
  #version           = "0.1.0"
  namespace         = local.minio-ns
  dependency_update = "true"

  set {
    name  = "persistence.size"
    value = "1Gi"
  }
  set {
    name  = "auth.rbac.enabled"
    value = "false"
  }

  depends_on = [
    kubernetes_namespace.minio,
  ]
}
