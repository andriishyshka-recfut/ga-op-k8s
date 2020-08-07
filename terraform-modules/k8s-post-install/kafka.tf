
resource "kubernetes_namespace" "kafka-system" {
  metadata {
    name = "kafka-system"
    # labels = {
    #   istio-injection = "enabled"
    # }
  }
  depends_on = [
    var.node_pool,
  ]
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
    environment = {
      CLUSTER_SETTINGS        = jsonencode(var.settings)
      CLUSTER                 = var.cluster
      ANSIBLE_STDOUT_CALLBACK = "debug"
      HOST                    = var.gke_cluster_endpoint
      API_KEY                 = var.gke_bearer_token
      CLUSTER_CA_CERTIFICATE  = var.cluster_ca_certificate
      k8s_apply_value         = "~/kafka_crd"
      from_file               = "yes"
    }
  }
  depends_on = [
    kubernetes_namespace.kafka-system
  ]
}
