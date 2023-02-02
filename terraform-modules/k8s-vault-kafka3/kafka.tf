


resource "helm_release" "kafka_operator" {
  name       = "kafka-operator"
  chart      = "${path.module}/strimzi-kafka-operator"
  wait       = true
  atomic     = true
  namespace  = local.kafkaNs
  timeout    = 900
}


resource "helm_release" "kafka_cluster" {
  name      = "kafka-cluster"
  chart     = "${path.module}/kafka"
  namespace = local.kafkaNs
  wait      = true 
  atomic    = true
  set {
    name = "subdomain"
    value = "${var.Settings.clusters[var.Cluster].subdomain}.${var.Settings.clusters[var.Cluster].domain}"
  }
  set {
    name = "diskSize"
    value = local.diskSize
  }
  set {
    name = "cpuReuest"
    value = local.request.cpu
  }
  set {
    name = "memReuest"
    value = local.request.memory
  }
  set {
    name = "memLimit"
    value = local.limit.memory
  }
  set {
    name = "cpuLimit"
    value = local.limit.cpu
  }
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
      statusPath     = "conditions[2].type"
      requiredStatus = "Ready"
    })
  }
  depends_on = [
    helm_release.kafka_cluster
  ]
}
