resource "helm_release" "red_panda_console" {
  name       = "rp-console"
  chart      = "console"
  repository = "https://charts.redpanda.com"
  wait       = true
  atomic     = true
  namespace  = local.kafkaNs
  timeout    = 900
  set {
    name  = "console.config.kafka.brokers[0]"
    value = "kafka-cluster-kafka-bootstrap:9092"
  }
  depends_on = [
    helm_release.kafka_cluster,
    null_resource.ansible_wait_for_kafka
  ]
}