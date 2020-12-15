
resource "null_resource" "ansible_istio_playbook" {
  triggers = {
    //always_run = "${timestamp()}"
    // istio_version_change = var.Settings.clusters[var.Cluster].istio_version
    playbook_contents = md5(file("${path.module}/../../ansible/istio.yml"))
  }
  provisioner "local-exec" {
    command     = <<COMMAND
    cd  ${path.module}/../../ansible && \
    ansible-playbook istio.yml \
      -e 'ansible_python_interpreter=/usr/bin/python3'
COMMAND
    environment = local.ansibleEnvs
  }
}
