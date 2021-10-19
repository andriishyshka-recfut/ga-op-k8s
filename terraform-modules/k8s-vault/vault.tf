resource "kubernetes_service_account" "vault" {
  metadata {
    name      = "vault"
    namespace = "kube-system"
  }
}

data "kubernetes_secret" "vault" {
  metadata {
    name      = kubernetes_service_account.vault.default_secret_name
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
    environment = merge(local.ansibleEnvs, {
      kubernetes_host    = local.gkeClusterEndpoint
      kubernetes_ca_cert = lookup(data.kubernetes_secret.vault.data, "ca.crt")
      token_reviewer_jwt = lookup(data.kubernetes_secret.vault.data, "token")
      k8s_sa_token       = lookup(data.kubernetes_secret.cluster_admin_creds.data, "token")
      k8s_sa_ca_cert     = lookup(data.kubernetes_secret.cluster_admin_creds.data, "ca.crt")
    })
  }
  depends_on = [
    null_resource.ansible_initial_provisioning_vault_playbook
  ]
}
