

resource "google_os_login_ssh_public_key" "cache" {
  user                 = data.google_client_openid_userinfo.userinfo_of_account_who_running_terraform.email
  key                  = data.external.onetime_ssh_key.result["pub_certificate"]
  expiration_time_usec = data.external.onetime_ssh_key.result["expiration_date"]
}



data "google_compute_address" "bastion" {
  name = "envoy"
}



resource "null_resource" "ansible_bastion_playbook" {
  triggers = {
    //always_run = "${timestamp()}"
    playbook_contents = md5(file("${path.module}/../../ansible/bastion.yml"))
    Color             = local.activeCluster
  }
  provisioner "local-exec" {
    command = <<COMMAND
    cd  ${path.module}/../../ansible && \
    ansible-playbook bastion.yml \
      --user  sa_${data.google_service_account.account_who_running_terraform.unique_id} \
      -i ${data.google_compute_address.bastion.address},
COMMAND


    environment = local.ansibleEnvs

  }
  depends_on = [ google_os_login_ssh_public_key.cache ]
}
