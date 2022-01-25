
resource "helm_release" "operator" {
  name = "redis-operator"
  chart      = "redis-operator"
  repository = "https://spotahome.github.io/redis-operator"
  #version           = "0.1.0"
  namespace         = "redis-operator-ns"
  dependency_update = "true"
}
