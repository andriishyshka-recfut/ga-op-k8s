resource "helm_release" "kowl" {
  name       = "kowl"
  chart      = "kowl"
  repository = "https://raw.githubusercontent.com/cloudhut/charts/master/archives"
  wait       = true
  atomic     = true
  namespace  = local.kafkaNs
  timeout = 900
  set {
    name = "kowl.config.kafka.brokers[0]"
    value = "kafka-cluster-kafka-bootstrap:9092"
  }
  depends_on = [
    helm_release.kafka_cluster,
  ]
}
