

resource "google_os_login_ssh_public_key" "cache" {
  user                 = data.google_client_openid_userinfo.me.email
  key                  = data.external.data.result["pub_certificate"]
  expiration_time_usec = data.external.data.result["expiration_date"]
}

#output "expiration_date" {
#value = data.external.data.result["expiration_date"]
#}
#output "pub_certificate" {
#value = data.external.data.result["pub_certificate"]
#}






resource "local_file" "ansible_gcp_inventory" {
  content  = templatefile("${path.module}/../../ansible/inventory.gcp.yml.tmpl", { project = data.google_service_account.me.project })
  filename = "${path.module}/../../ansible/inventory.gcp.yaml"
}



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

resource "null_resource" "ansible_bastion_playbook" {
  triggers = {
    //always_run = "${timestamp()}"
    istio_change                 = null_resource.ansible_istio_playbook.id
    gke_cluster_change           = google_container_cluster.cluster.id
    playbook_contents            = md5(file("${path.module}/../../ansible/bastion.yml"))
    upstream_py_contents         = md5(file("${path.module}/../../ansible/files/upstream.py"))
    upstream_dockerfile_contents = md5(file("${path.module}/../../ansible/files/upstream-Dockerfile"))
  }
  provisioner "local-exec" {
    command = <<COMMAND
    cd  ${path.module}/../../ansible && \
    ansible-playbook bastion.yml \
      --user  sa_${data.google_service_account.me.unique_id} \
      -e 'ansible_python_interpreter=/usr/bin/python3' \
      -i ./inventory.gcp.yaml
COMMAND


    environment = {
      CLUSTER_SETTINGS        = jsonencode(var.settings.cluster_settings)
      CLUSTER                 = var.cluster
      ANSIBLE_STDOUT_CALLBACK = "debug"
      HOST                    = "https://${google_container_cluster.cluster.endpoint}"
      API_KEY                 = data.google_client_config.default.access_token
      CLUSTER_CA_CERTIFICATE  = base64decode(google_container_cluster.cluster.master_auth[0].cluster_ca_certificate, )
      BASTION_DNS             = var.settings.bastion_dns
    }
  }
  depends_on = [
    google_container_node_pool.cluster_preemptible_nodes,
    local_file.ansible_gcp_inventory,
    null_resource.ansible_istio_playbook,
    kubernetes_cluster_role_binding.bastion_anon_access
  ]
}

resource "null_resource" "ansible_post_install_verification_playbook" {
  triggers = {
    //always_run = "${timestamp()}"
    bastion_change     = null_resource.ansible_bastion_playbook.id
    istio_change       = null_resource.ansible_istio_playbook.id
    gke_cluster_change = google_container_cluster.cluster.id
    playbook_contents  = md5(file("${path.module}/../../ansible/test-workload.yml"))
  }
  provisioner "local-exec" {
    command = <<COMMAND
    cd  ${path.module}/../../ansible && \
    ansible-playbook test-workload.yml \
      --user  sa_${data.google_service_account.me.unique_id} \
      -e 'ansible_python_interpreter=/usr/bin/python3' \
      -i ./inventory.gcp.yaml
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
    null_resource.ansible_istio_playbook,
    helm_release.cert-manager,
    null_resource.ansible_bastion_playbook,

  ]
}
