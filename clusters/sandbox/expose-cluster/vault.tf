# Scale in  active and scale out inactive vault statefulsets

resource "null_resource" "ansible_expose_vault_with_istio" {
  count = local.istioExposeToggle
  triggers = {
    template = md4(file("${path.module}/vault-gateway.yaml.tmpl"))
    vault    = helm_release.vault.id
  }
  provisioner "local-exec" {
    command = <<COMMAND
    $($expose_vault_with_istio) &&\
    cd  ${path.module}/../../ansible && \
    ansible-playbook k7s-apply.yml \
      -e 'ansible_python_interpreter=/usr/bin/python2'
COMMAND
    environment = merge(local.ansibleEnvs, {
      k7s_apply_value = templatefile("${path.module}/vault-gateway.yaml.tmpl", { vault_fqdn = local.vaultFqdn })
    })
  }
  depends_on = [
    helm_release.vault,
    null_resource.ansible_initial_provisioning_vault_playbook,
  ]
}
