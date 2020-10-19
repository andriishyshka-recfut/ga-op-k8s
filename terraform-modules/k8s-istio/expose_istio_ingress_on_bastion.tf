

resource "google_os_login_ssh_public_key" "cache" {
  count                = local.bastion_expose_toggle
  user                 = data.google_client_openid_userinfo.me.email
  key                  = data.external.data.result["pub_certificate"]
  expiration_time_usec = data.external.data.result["expiration_date"]
}


resource "local_file" "ansible_gcp_inventory" {
  count    = local.bastion_expose_toggle
  content  = templatefile("${path.module}/../../ansible/inventory.gcp.yml.tmpl", { project = data.google_project.project.number })
  filename = "${path.module}/../../ansible/inventory.gcp.yaml"
}




resource "null_resource" "ansible_bastion_playbook" {
  count = local.bastion_expose_toggle
  triggers = {
    //always_run = "${timestamp()}"
    istio_change      = null_resource.ansible_istio_playbook.id
    playbook_contents = md5(file("${path.module}/../../ansible/bastion.yml"))
  }
  provisioner "local-exec" {
    command = <<COMMAND
    cd  ${path.module}/../../ansible && \
    ansible-playbook bastion.yml \
      --user  sa_${data.google_service_account.me.unique_id} \
      -e 'ansible_python_interpreter=/usr/bin/python3' \
      -i ./inventory.gcp.yaml
COMMAND


    environment = local.ansible_envs

  }
  depends_on = [
    local_file.ansible_gcp_inventory,
    null_resource.ansible_istio_playbook,
    kubernetes_cluster_role_binding.bastion_anon_access
  ]
}
