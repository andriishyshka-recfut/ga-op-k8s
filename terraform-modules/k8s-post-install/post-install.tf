

resource "google_os_login_ssh_public_key" "cache" {
  user                 = data.google_client_openid_userinfo.me.email
  key                  = data.external.data.result["pub_certificate"]
  expiration_time_usec = data.external.data.result["expiration_date"]
}


resource "local_file" "ansible_gcp_inventory" {
  content  = templatefile("${path.module}/../../ansible/inventory.gcp.yml.tmpl", { project = data.google_service_account.me.project })
  filename = "${path.module}/../../ansible/inventory.gcp.yaml"
}



resource "null_resource" "ansible_bastion_playbook" {
  count = lookup(var.settings[var.cluster], "active", false) ? 1 : 0
  triggers = {
    //always_run = "${timestamp()}"
    istio_change                 = null_resource.ansible_istio_playbook.id
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
      CLUSTER_SETTINGS        = jsonencode(var.settings)
      CLUSTER                 = var.cluster
      ANSIBLE_STDOUT_CALLBACK = "debug"
      HOST                    = var.gke_cluster_endpoint
      API_KEY                 = var.gke_bearer_token
      CLUSTER_CA_CERTIFICATE  = var.cluster_ca_certificate
      BASTION_DNS             = var.settings.bastion_dns
    }
  }
  depends_on = [
    var.node_pool,
    local_file.ansible_gcp_inventory,
    null_resource.ansible_istio_playbook,
    kubernetes_cluster_role_binding.bastion_anon_access
  ]
}

resource "null_resource" "ansible_post_install_verification_playbook" {
  triggers = {
    //always_run = "${timestamp()}"
    # bastion_change    = lookup(null_resource.ansible_bastion_playbook[0], "id", "default")
    istio_change      = null_resource.ansible_istio_playbook.id
    playbook_contents = md5(file("${path.module}/../../ansible/test-workload.yml"))
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
      CLUSTER_SETTINGS        = jsonencode(var.settings)
      CLUSTER                 = var.cluster
      ANSIBLE_STDOUT_CALLBACK = "debug"
      HOST                    = var.gke_cluster_endpoint
      API_KEY                 = var.gke_bearer_token
      CLUSTER_CA_CERTIFICATE  = var.cluster_ca_certificate
    }
  }
  depends_on = [
    var.node_pool,
    local_file.ansible_gcp_inventory,
    null_resource.ansible_istio_playbook,
    helm_release.cert-manager,
    null_resource.ansible_bastion_playbook,

  ]
}
