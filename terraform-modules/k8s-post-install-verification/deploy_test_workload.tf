
data "google_client_openid_userinfo" "userinfo_of_account_who_running_terraform" {
}

data "google_service_account" "account_who_running_terraform" {
  account_id = element(split("@", data.google_client_openid_userinfo.userinfo_of_account_who_running_terraform.email), 0)
}

variable "GkeClusterConnectionSettings" {}
variable "Settings" {}
variable "Cluster" {}
variable "Color" {}


locals {
  ansibleEnvs = merge(var.GkeClusterConnectionSettings, {
    CLUSTER_SETTINGS        = jsonencode(var.Settings)
    CLUSTER                 = var.Cluster
    COLOR                   = var.Color
    ANSIBLE_STDOUT_CALLBACK = "debug"
    BASTION_DNS             = var.Settings.bastion_dns
  })
}

resource "null_resource" "ansible_post_install_verification_playbook" {
  triggers = {
    playbook_contents = md5(file("${path.module}/../../ansible/test-workload.yml"))
  }
  provisioner "local-exec" {
    command = <<COMMAND
    cd  ${path.module}/../../ansible && \
    ansible-playbook test-workload.yml \
      --user  sa_${data.google_service_account.account_who_running_terraform.unique_id} \
      -e 'ansible_python_interpreter=/usr/bin/python3' \
      -i ./inventory.gcp.yaml
COMMAND

    environment = local.ansibleEnvs
  }
}
