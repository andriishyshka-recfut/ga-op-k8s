resource "null_resource" "ansible_cert-manager_vault_integration_playbook" {
  count = var.settings.clusters[var.cluster].vault_integration.enabled ? 1 : 0
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
    environment = {
      CLUSTER_SETTINGS        = jsonencode(var.settings)
      CLUSTER                 = var.cluster
      ANSIBLE_STDOUT_CALLBACK = "debug"
      HOST                    = var.gke_cluster_endpoint
      API_KEY                 = var.gke_bearer_token
      CLUSTER_CA_CERTIFICATE  = var.cluster_ca_certificate
      k8s_apply_value = templatefile("${path.module}/certificates.yaml.tmpl",
        { default_secret_name = data.kubernetes_service_account.cert-manager.default_secret_name,
          vault_addr          = lookup(var.settings.clusters[var.cluster].vault_integration, "connection", "remote") == "local" ? "http://vault.vault.svc" : var.settings.clusters[var.cluster].vault_integration.vault_addr,
      cluster = var.cluster, ca = base64encode(data.external.root_ca.result.ca), connection = lookup(var.settings.clusters[var.cluster].vault_integration, "connection", "remote") })
    }
  }
  depends_on = [
    var.node_pool,
    helm_release.cert-manager,
    null_resource.ansible_vault_k8s_auth
  ]
}
