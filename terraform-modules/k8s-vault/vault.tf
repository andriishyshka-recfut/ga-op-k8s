resource "kubernetes_service_account" "vault" {
  count = var.settings.clusters[var.cluster].vault_integration.enabled ? 1 : 0
  metadata {
    name      = "vault"
    namespace = "kube-system"
  }
}

data "kubernetes_secret" "vault" {
  count = var.settings.clusters[var.cluster].vault_integration.enabled ? 1 : 0
  metadata {
    name      = kubernetes_service_account.vault[count.index].default_secret_name
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role_binding" "vault" {
  count = var.settings.clusters[var.cluster].vault_integration.enabled ? 1 : 0
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
  count = var.settings.clusters[var.cluster].vault_integration.enabled ? 1 : 0
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
      CLUSTER_SETTINGS        = jsonencode(var.settings)
      CLUSTER                 = var.cluster
      ANSIBLE_STDOUT_CALLBACK = "debug"
      kubernetes_host         = var.gke_cluster_endpoint
      kubernetes_ca_cert      = lookup(data.kubernetes_secret.vault[count.index].data, "ca.crt")
      token_reviewer_jwt      = lookup(data.kubernetes_secret.vault[count.index].data, "token")
      HOST                    = var.gke_cluster_endpoint
      API_KEY                 = var.gke_bearer_token
      CLUSTER_CA_CERTIFICATE  = var.cluster_ca_certificate
      k8s_sa_token            = lookup(data.kubernetes_secret.admin.data, "token")
      k8s_sa_ca_cert          = lookup(data.kubernetes_secret.admin.data, "ca.crt")
    }
  }
  depends_on = [
    null_resource.ansible_vault_playbook
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
