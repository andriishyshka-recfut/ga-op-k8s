#
resource "kubernetes_namespace" "redis-system" {
  metadata {
    name = "redis-system"
    # labels = {
    #   istio-injection = "enabled"
    # }
  }
  depends_on = [
    var.node_pool,
  ]
}


resource "null_resource" "ansible_redis_crd_playbook" {
  triggers = {
    # playbook_contents  = md5(file("${path.module}/certificates.yaml.tmpl"))
  }
  # provisioner "file" {
  #   content     = data.external.eck_crd.result.crd
  #   destination = "~/eck_crd"
  #
  # }
  provisioner "local-exec" {
    command = <<COMMAND
    wget -O ~/redis_crd https://raw.githubusercontent.com/spotahome/redis-operator/master/example/operator/all-redis-operator-resources.yaml &&\
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
      k8s_apply_value         = "~/redis_crd"
      from_file               = "yes"
      namespace               = "redis-system"
    }
  }
  depends_on = [
    # google_container_node_pool.cluster_preemptible_nodes,
    # kubernetes_namespace.-system
  ]
}
