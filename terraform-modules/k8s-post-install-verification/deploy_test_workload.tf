


// Service account and project info
data "google_client_openid_userinfo" "me" {
}
data "google_service_account" "me" {
  account_id = element(split("@", data.google_client_openid_userinfo.me.email), 0)
}

variable "gke_cluster_connection_settings" {}

// Cluster variables and settings from common-vars module
variable "settings" {}
variable "cluster" {}
variable "color" {}

# variable "vault_resources" {}


locals {

  ansible_envs = merge(var.gke_cluster_connection_settings, {
    CLUSTER_SETTINGS        = jsonencode(var.settings)
    CLUSTER                 = var.cluster
    COLOR                   = var.color
    ANSIBLE_STDOUT_CALLBACK = "debug"
    BASTION_DNS             = var.settings.bastion_dns
  })

}

resource "null_resource" "ansible_post_install_verification_playbook" {
  triggers = {
    //always_run = "${timestamp()}"
    # bastion_change    = lookup(null_resource.ansible_bastion_playbook[0], "id", "default")
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

    environment = local.ansible_envs
  }
}
