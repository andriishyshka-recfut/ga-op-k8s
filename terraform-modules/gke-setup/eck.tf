resource "kubernetes_namespace" "elastic-system" {
  metadata {
    name = "elastic-system"
    labels = {
      istio-injection = "enabled"
    }
  }
  depends_on = [
    google_container_node_pool.cluster_preemptible_nodes
  ]
}



resource "null_resource" "ansible_eck_crd_playbook" {
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
    wget -O ~/eck_crd https://download.elastic.co/downloads/eck/${lookup(var.settings.cluster_settings[var.cluster], "eck_version", "1.1.2")}/all-in-one.yaml &&\
    cd  ${path.module}/../../ansible && \
    ansible-playbook k8s-apply.yml \
    -e 'ansible_python_interpreter=/usr/bin/python3'
COMMAND
    environment = {
      CLUSTER_SETTINGS        = jsonencode(var.settings.cluster_settings)
      CLUSTER                 = var.cluster
      ANSIBLE_STDOUT_CALLBACK = "debug"
      HOST                    = "https://${google_container_cluster.cluster.endpoint}"
      API_KEY                 = data.google_client_config.default.access_token
      CLUSTER_CA_CERTIFICATE  = base64decode(google_container_cluster.cluster.master_auth[0].cluster_ca_certificate, )
      k8s_apply_value         = "~/eck_crd"
      from_file               = "yes"
    }
  }
  depends_on = [
    google_container_node_pool.cluster_preemptible_nodes,
    kubernetes_namespace.elastic-system
  ]
}
