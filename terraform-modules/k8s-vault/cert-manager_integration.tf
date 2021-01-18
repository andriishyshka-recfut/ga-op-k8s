

data "kubernetes_service_account" "cert_manager" {
  count = local.certManagerIssuerToggle
  metadata {
    name      = "${var.Cluster}-cert-manager"
    namespace = "kube-system"
  }
}

resource "null_resource" "ansible_cert_manager_vault_integration_playbook" {
  count = local.certManagerIssuerToggle
  triggers = {
    vault_auth        = null_resource.ansible_vault_k8s_auth.id
    playbook_contents = md5(file("${path.module}/certificates.yaml.tmpl"))
  }
  provisioner "local-exec" {
    command = <<COMMAND
    cd  ${path.module}/../../ansible && \
    ansible-playbook k8s-apply.yml \
      -e 'ansible_python_interpreter=/usr/bin/python3'
COMMAND
    environment = merge(local.ansibleEnvs, {
      k8s_apply_value = templatefile("${path.module}/certificates.yaml.tmpl",
        { default_secret_name = data.kubernetes_service_account.cert_manager[0].default_secret_name
          vault_addr          = local.vaultLocalUrl
          cluster             = local.cluster
          color               = var.Color
          connection          = local.connection
      })
    })
  }
  depends_on = [
    null_resource.ansible_vault_k8s_auth
  ]
}
