

data "kubernetes_service_account" "cert-manager" {
  count = local.create_cert-manager_issuer
  metadata {
    name      = "${var.Cluster}-cert-manager"
    namespace = "kube-system"
  }
}

resource "null_resource" "ansible_cert_manager_vault_integration_playbook" {
  count = local.create_cert-manager_issuer
  triggers = {
    vault_auth        = null_resource.ansible_vault_k8s_auth[0].id
    playbook_contents = md5(file("${path.module}/certificates.yaml.tmpl"))
  }
  provisioner "local-exec" {
    command = <<COMMAND
    cd  ${path.module}/../../ansible && \
    ansible-playbook k8s-apply.yml \
      -e 'ansible_python_interpreter=/usr/bin/python3'
COMMAND
    environment = merge(local.ansible_envs, {
      k8s_apply_value = templatefile("${path.module}/certificates.yaml.tmpl",
        { default_secret_name = data.kubernetes_service_account.cert-manager[0].default_secret_name
          vault_addr          = local.vault_addr
          cluster             = local.cluster
          connection          = local.connection
      })
    })
  }
  depends_on = [
    null_resource.ansible_vault_k8s_auth
  ]
}
