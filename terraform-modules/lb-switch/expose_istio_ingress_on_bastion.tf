

resource "google_os_login_ssh_public_key" "cache" {
  user                 = data.google_client_openid_userinfo.userinfo_of_account_who_running_terraform.email
  key                  = data.external.onetime_ssh_key.result["pub_certificate"]
  expiration_time_usec = data.external.onetime_ssh_key.result["expiration_date"]
}


resource "local_file" "ansible_gcp_inventory" {
  content  = templatefile("${path.module}/../../ansible/inventory.gcp.yml.tmpl", { project = data.google_project.current_project.number })
  filename = "${path.module}/../../ansible/inventory.gcp.yaml"
}




resource "null_resource" "ansible_bastion_playbook" {
  triggers = {
    //always_run = "${timestamp()}"
    playbook_contents = md5(file("${path.module}/../../ansible/bastion.yml"))
    Color             = var.Color
  }
  provisioner "local-exec" {
    command = <<COMMAND
    cd  ${path.module}/../../ansible && \
    ansible-playbook bastion.yml \
      --user  sa_${data.google_service_account.account_who_running_terraform.unique_id} \
      -e 'ansible_python_interpreter=/usr/bin/python3' \
      -i ./inventory.gcp.yaml
COMMAND


    environment = local.ansibleEnvs

  }
  depends_on = [
    local_file.ansible_gcp_inventory,
    kubernetes_cluster_role_binding.bastion_anon_access
  ]
}
