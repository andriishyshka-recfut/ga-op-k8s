resource "helm_release" "red_panda_console" {
  name       = "rp3-console"
  chart      = "console"
  repository = "https://packages.vectorized.io/public/console/helm/charts/"
  wait       = true
  atomic     = true
  namespace  = local.kafkaNs
  timeout    = 900
  set {
    name  = "console.config.kafka.brokers[0]"
    value = "kafka-cluster-kafka-bootstrap:9092"
  }
  depends_on = [
    helm_release.kafka3_cluster,
    null_resource.ansible_wait_for_kafka
  ]
}