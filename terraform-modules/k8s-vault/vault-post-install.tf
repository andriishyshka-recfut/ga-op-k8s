
resource "null_resource" "ansible_vault_playbook" {
  count = local.do_initial_provisioning
  triggers = {
    //always_run = "${timestamp()}"
    // istio_version_change = var.settings.clusters[var.cluster].istio_version
    oidc_discovery_url = var.oidc_discovery_url
    playbook_contents  = md5(file("${path.module}/../../ansible/vault-postinstall.yml"))
    vault              = helm_release.vault.id

  }
  provisioner "local-exec" {
    command = <<COMMAND
    cd  ${path.module}/../../ansible && \
    ansible-playbook vault-postinstall.yml \
      -e 'ansible_python_interpreter=/usr/bin/python3'
COMMAND
    environment = merge(local.ansible_envs, {
      oidc_client_id     = var.oidc_client_id
      oidc_discovery_url = var.oidc_discovery_url
      oidc_client_secret = var.oidc_client_secret
    })
  }
  depends_on = [
    helm_release.vault
  ]
}

resource "null_resource" "ansible_expose_vault_with_istio" {
  count = local.istio_expose
  triggers = {
    template = md5(file("${path.module}/vault-gateway.yaml.tmpl"))
    vault    = helm_release.vault.id
  }
  provisioner "local-exec" {
    command = <<COMMAND
    $($expose_vault_with_istio) &&\
    cd  ${path.module}/../../ansible && \
    ansible-playbook k8s-apply.yml \
      -e 'ansible_python_interpreter=/usr/bin/python3'
COMMAND
    environment = merge(local.ansible_envs, {
      k8s_apply_value = templatefile("${path.module}/vault-gateway.yaml.tmpl", { vault_fqdn = local.vault_fqdn })
    })
  }
  depends_on = [
    helm_release.vault,
    null_resource.ansible_vault_playbook,
  ]
}
