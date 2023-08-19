
resource "helm_release" "operator" {
  name = "redis-operator"
  chart      = "redis-operator"
  repository = "https://spotahome.github.io/redis-operator"
  version           = "3.2.9"
  namespace         = "redis-operator-ns"
  dependency_update = "true"
}
