resource "kubernetes_namespace" "elastic_operator_ns" {
  metadata {
    name = "elastic-system"
    labels = {
      istio-injection = "enabled"
    }
  }
}



resource "null_resource" "ansible_eck_crd_playbook" {
  triggers = {
    # playbook_contents  = md5(file("${path.module}/certificates.yaml.tmpl"))
    version = local.eckVersion
  }

  provisioner "local-exec" {
    command = <<COMMAND
    wget -O ~/eck_crd https://download.elastic.co/downloads/eck/${local.eckVersion}/all-in-one.yaml &&\
    cd  ${path.module}/../../ansible && \
    ansible-playbook k8s-apply.yml \
    -e 'ansible_python_interpreter=/usr/bin/python3'
COMMAND
    environment = merge(local.ansibleEnvs, {
      k8s_apply_value = "~/eck_crd",
      from_file       = "yes"
    })
  }
  depends_on = [
    # google_container_node_pool.cluster_preemptible_nodes,
    kubernetes_namespace.elastic_operator_ns
  ]
}
