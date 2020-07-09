
resource "null_resource" "ansible_istio_playbook" {
  triggers = {
    //always_run = "${timestamp()}"
    // istio_version_change = var.settings.cluster_settings[var.cluster].istio_version
    gke_cluster_change = google_container_cluster.cluster.id
    playbook_contents  = md5(file("${path.module}/../../ansible/istio.yml"))
  }
  provisioner "local-exec" {
    command = <<COMMAND
    cd  ${path.module}/../../ansible && \
    ansible-playbook istio.yml \
      -e 'ansible_python_interpreter=/usr/bin/python3'
COMMAND
    environment = {
      CLUSTER_SETTINGS        = jsonencode(var.settings.cluster_settings)
      CLUSTER                 = var.cluster
      ANSIBLE_STDOUT_CALLBACK = "debug"
      HOST                    = "https://${google_container_cluster.cluster.endpoint}"
      API_KEY                 = data.google_client_config.default.access_token
      CLUSTER_CA_CERTIFICATE  = base64decode(google_container_cluster.cluster.master_auth[0].cluster_ca_certificate, )
    }
  }
  depends_on = [
    google_container_node_pool.cluster_preemptible_nodes,
    local_file.ansible_gcp_inventory,
    null_resource.ansible_cert-manager_playbook
  ]
}



resource "null_resource" "ansible_create_istio_ca" {
  count = var.settings.cluster_settings[var.cluster].istio.use_vault_ca ? 1 : 0
  triggers = {

    gke_cluster_change = google_container_cluster.cluster.id
    playbook_contents  = md5(file("${path.module}/certificates.yaml.tmpl"))
  }
  provisioner "local-exec" {
    command = <<COMMAND
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
      k8s_apply_value = templatefile("${path.module}/certificates.yaml.tmpl",
        { default_secret_name = data.kubernetes_service_account.cert-manager.default_secret_name,
      vault_addr = var.settings.cluster_settings[var.cluster].vault_integration.connection == "local" ? var.settings.cluster_settings[var.cluster].vault_integration.vault_addr : "http://vault.vault.svc" })
    }
  }
  depends_on = [
    null_resource.ansible_istio_playbook,
    null_resource.ansible_cert-manager_playbook
  ]
}
