


resource "helm_release" "kafka_operator" {
  name       = "kafka-operator"
  chart      = "strimzi-kafka-operator"
  repository = "https://strimzi.io/charts/"
  wait       = true
  atomic     = true
  namespace  = local.kafkaNs
  timeout    = 900
  version    = "0.24.0"
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

resource "null_resource" "ansible_wait_for_kafka" {

  triggers = {
    playbook_contents = md5(file("${path.module}/../../ansible/k8s-wait-for.yml"))
    kafka_id          = helm_release.kafka_cluster.id
    kafka_operator_id = helm_release.kafka_operator.id
  }
  provisioner "local-exec" {
    command = <<COMMAND
    cd ${path.module}/../../ansible &&\
    ansible-playbook k8s-wait-for.yml

COMMAND
    environment = merge(local.ansibleEnvs, {
      name           = "kafka-cluster"
      kind           = "kafka"
      namespace      = local.kafkaNs
      apiVersion     = "kafka.strimzi.io/v1beta2"
      statusPath     = "conditions[1].type"
      requiredStatus = "Ready"
    })
  }
  depends_on = [
    helm_release.kafka_cluster
  ]
}
