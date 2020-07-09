
# resource "local_file" "ansible_gcp_inventory" {
#   content  = templatefile("${path.root}/../ansible/inventory.gcp.yml.tmpl", { project = data.google_service_account.me.project })
#   filename = "${path.root}/../ansible/inventory.gcp.yaml"
# }
data "google_client_openid_userinfo" "me" {
}
data "google_service_account" "me" {
  account_id = element(split("@", data.google_client_openid_userinfo.me.email), 0)
}
resource "null_resource" "ansible_vault_playbook" {
  triggers = {
    //always_run = "${timestamp()}"
    // istio_version_change = var.settings.cluster_settings[var.cluster].istio_version
    oidc_discovery_url = var.oidc_discovery_url
    playbook_contents  = md5(file("${path.module}/../../ansible/vault-postinstall.yml"))
    vault              = helm_release.vault.id

  }
  provisioner "local-exec" {
    command = <<COMMAND
    cd  ${path.module}/../../ansible && \
    ansible-playbook vault-postinstall.yml \
      --user  sa_${data.google_service_account.me.unique_id} \
      -e 'ansible_python_interpreter=/usr/bin/python3'
COMMAND
    environment = {
      CLUSTER_SETTINGS        = jsonencode(var.settings.cluster_settings)
      CLUSTER                 = var.cluster
      ANSIBLE_STDOUT_CALLBACK = "debug"
      vault_addr              = "https://vault.${var.cluster}.${var.settings.cluster_settings[var.cluster].domain}"
      # CA_CERT                 = tls_self_signed_cert.example.cert_pem
      oidc_client_id         = var.oidc_client_id
      oidc_discovery_url     = var.oidc_discovery_url
      oidc_client_secret     = var.oidc_client_secret
      HOST                   = var.gke_cluster_endpoint
      API_KEY                = var.gke_bearer_token
      CLUSTER_CA_CERTIFICATE = var.cluster_ca_certificate
    }
  }
  depends_on = [
    helm_release.vault
  ]
}

resource "null_resource" "ansible_expose_vault_with_istio" {

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
      CLUSTER_SETTINGS        = jsonencode(var.settings.cluster_settings)
      CLUSTER                 = var.cluster
      ANSIBLE_STDOUT_CALLBACK = "debug"
      HOST                    = var.gke_cluster_endpoint
      API_KEY                 = var.gke_bearer_token
      CLUSTER_CA_CERTIFICATE  = var.cluster_ca_certificate
      k8s_apply_value         = templatefile("${path.module}/vault-gateway.yaml.tmpl", { vault_fqdn = "vault.${var.cluster}.${var.settings.cluster_settings[var.cluster].domain}" })
      expose_vault_with_istio = var.expose_vault_with_istio == true ? "true" : "false"
    }
  }
  depends_on = [
    helm_release.vault,
    null_resource.ansible_vault_playbook,
    var.expose_vault_with_istio
  ]
}
