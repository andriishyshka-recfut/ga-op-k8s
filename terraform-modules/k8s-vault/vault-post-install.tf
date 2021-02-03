
resource "null_resource" "ansible_initial_provisioning_vault_playbook" {
  count = local.initialProvisioningToggle
  triggers = {
    oidc_discovery_url = var.OidcDiscoveryUrl
    playbook_contents  = md5(file("${path.module}/../../ansible/vault-postinstall.yml"))
    vault              = helm_release.vault.id

  }
  provisioner "local-exec" {
    command = <<COMMAND
    cd  ${path.module}/../../ansible && \
    ansible-playbook vault-postinstall.yml \
      -e 'ansible_python_interpreter=/usr/bin/python3'
COMMAND
    environment = merge(local.ansibleEnvs, {
      oidc_client_id     = var.OidcClientId
      oidc_discovery_url = var.OidcDiscoveryUrl
      oidc_client_secret = var.OidcClientSecret
    })
  }
  depends_on = [
    helm_release.vault
  ]
}
