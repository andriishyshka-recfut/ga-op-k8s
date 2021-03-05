


resource "helm_release" "kafka_operator" {
  name       = "kafka-operator"
  chart      = "strimzi-kafka-operator"
  repository = "https://strimzi.io/charts/"
  wait       = true
  atomic     = true
  namespace  = local.kafkaNs
  timeout = 900
}


resource "helm_release" "kafka_cluster" {
  name      = "kafka-cluster"
  chart     = "${path.module}/kafka"
  namespace = local.kafkaNs
  wait      = true
  atomic    = true
  depends_on = [
    helm_release.kafka_operator,
  ]
}
