
resource "local_file" "ansible_gcp_inventory" {
    content     = templatefile("${path.root}/../ansible/inventory.gcp.yml.tmpl",{project = data.google_service_account.me.project })
    filename = "${path.root}/../ansible/inventory.gcp.yaml"
}
data "google_client_openid_userinfo" "me" {
}
data "google_service_account" "me" {
  account_id = element(split("@",data.google_client_openid_userinfo.me.email),0)
}
resource "null_resource" "ansible_vault_playbook" {
  triggers = {
    //always_run = "${timestamp()}"
    // istio_version_change = var.settings.cluster_settings[var.cluster].istio_version
  }
  provisioner "local-exec" {
    command = <<COMMAND
    cd  ${path.root}/../ansible && \
    ansible-playbook vault-postinstall.yml \
      --user  sa_${data.google_service_account.me.unique_id} \
      -e 'ansible_python_interpreter=/usr/bin/python3' \
      -i ./inventory.gcp.yaml -vvvv
COMMAND
    environment = {
    CLUSTER_SETTINGS = jsonencode(var.settings.cluster_settings)
    CLUSTER = var.cluster
    ANSIBLE_STDOUT_CALLBACK = "debug"
    VAULT_ADDR = "https://vault.${var.cluster}.${var.settings.cluster_settings[var.cluster].domain}"
    CA_CERT = tls_self_signed_cert.example.cert_pem
    }
  }
  depends_on = [
    local_file.ansible_gcp_inventory,
    tls_self_signed_cert.example,
    helm_release.vault
  ]
}
