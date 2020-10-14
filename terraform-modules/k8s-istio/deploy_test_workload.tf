
resource "null_resource" "ansible_post_install_verification_playbook" {
  count = local.test_workload_toggle
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

    environment = local.ansible_envs
  }
  depends_on = [
    null_resource.ansible_istio_playbook,
    null_resource.ansible_bastion_playbook,

  ]
}
