resource "kubernetes_service_account" "vault" {
  metadata {
    name      = "vault"
    namespace = "kube-system"
  }
}

data "kubernetes_secret" "vault" {
  metadata {
    name      = "${kubernetes_service_account.vault.default_secret_name}"
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role_binding" "vault" {
  metadata {
    name = "vault-auth"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "system:auth-delegator"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "vault"
    namespace = "kube-system"
  }
}


resource "null_resource" "ansible_vault_k8s_auth" {
  triggers = {
    playbook_contents = md5(file("${path.module}/../../ansible/vault-k8s-auth.yml"))
  }
  provisioner "local-exec" {
    command = <<COMMAND
    cd  ${path.module}/../../ansible && \
    ansible-playbook vault-k8s-auth.yml \
      -e 'ansible_python_interpreter=/usr/bin/python3'
COMMAND
    environment = {
      CLUSTER_SETTINGS        = jsonencode(var.settings.cluster_settings)
      CLUSTER                 = var.cluster
      ANSIBLE_STDOUT_CALLBACK = "debug"
      VAULT_ADDR              = "https://vault.${var.cluster}.${var.settings.cluster_settings[var.cluster].domain}"
      CA_CERT                 = var.vault_ca_certificate
      kubernetes_host         = var.vault_addr
      kubernetes_ca_cert      = lookup(data.kubernetes_secret.vault.data, "ca.crt")
      token_reviewer_jwt      = lookup(data.kubernetes_secret.vault.data, "token")
    }
  }
  depends_on = [
    var.vault_addr,
    var.vault_ca_certificate,
    var.vault_unsealed
  ]
}
# provider vault {
#   address = "https://vault.infra.digaweb.com"
# }
# resource "vault_auth_backend" "kubernetes" {
#   type = "kubernetes"
#   path = "k8s-${var.cluster}"
#   depends_on = [
#     google_container_cluster.cluster
#   ]
# }
#
# resource "vault_kubernetes_auth_backend_config" "example" {
#   backend            = vault_auth_backend.kubernetes.path
#   kubernetes_host    = "https://${google_container_cluster.cluster.endpoint}"
#   kubernetes_ca_cert = lookup(data.kubernetes_secret.vault.data, "ca.crt")
#   token_reviewer_jwt = lookup(data.kubernetes_secret.vault.data, "token")
# }
