
# resource "local_file" "ansible_gcp_inventory" {
#   content  = templatefile("${path.root}/../ansible/inventory.gcp.yml.tmpl", { project = data.google_service_account.me.project })
#   filename = "${path.root}/../ansible/inventory.gcp.yaml"
# }
resource "null_resource" "ansible_vault_playbook" {
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
    environment = {
      CLUSTER_SETTINGS        = jsonencode(var.settings)
      CLUSTER                 = var.cluster
      ANSIBLE_STDOUT_CALLBACK = "debug"
      oidc_client_id          = var.oidc_client_id
      oidc_discovery_url      = var.oidc_discovery_url
      oidc_client_secret      = var.oidc_client_secret
      HOST                    = var.gke_cluster_endpoint
      API_KEY                 = var.gke_bearer_token
      CLUSTER_CA_CERTIFICATE  = var.cluster_ca_certificate
    }
  }
  depends_on = [
    helm_release.vault
  ]
}

resource "null_resource" "ansible_expose_vault_with_istio" {
  count = var.settings.clusters[var.cluster][var.color].vault.istio_expose == true ? 1 : 0
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
    environment = {
      CLUSTER_SETTINGS        = jsonencode(var.settings)
      CLUSTER                 = var.cluster
      ANSIBLE_STDOUT_CALLBACK = "debug"
      HOST                    = var.gke_cluster_endpoint
      API_KEY                 = var.gke_bearer_token
      CLUSTER_CA_CERTIFICATE  = var.cluster_ca_certificate
      k8s_apply_value         = templatefile("${path.module}/vault-gateway.yaml.tmpl", { vault_fqdn = var.settings.clusters[var.cluster].vault.fqdn })
    }
  }
  depends_on = [
    helm_release.vault,
    null_resource.ansible_vault_playbook,
    null_resource.ansible_istio_playbook
  ]
}
