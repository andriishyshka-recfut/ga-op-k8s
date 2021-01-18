
resource "kubernetes_namespace" "kafka_system" {
  metadata {
    name = "kafka-system"
    # labels = {
    #   istio-injection = "enabled"
    # }
  }
}

resource "null_resource" "ansible_kafka_crd_playbook" {
  triggers = {
    # playbook_contents  = md5(file("${path.module}/certificates.yaml.tmpl"))
  }
  provisioner "local-exec" {
    command = <<COMMAND
    wget -O ~/kafka_crd https://strimzi.io/install/latest?namespace=kafka-system  &&\
    cd  ${path.module}/../../ansible && \
    ansible-playbook k8s-apply.yml \
    -e 'ansible_python_interpreter=/usr/bin/python3'
COMMAND
    environment = merge(local.ansibleEnvs, {
      k8s_apply_value = "~/kafka_crd",
      from_file       = "yes"
    })

  }
  depends_on = [
    kubernetes_namespace.kafka_system
  ]
}
