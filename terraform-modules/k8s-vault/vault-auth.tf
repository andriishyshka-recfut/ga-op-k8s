resource "null_resource" "auth_kubernetes_disable" {
  provisioner "local-exec" {
    command = <<-EOT
      vault auth disable k8s-${var.Cluster}-${var.Color} || exit
    EOT
    environment = {
      VAULT_ADDR = var.VaultAddress
    }
  }
}

resource "vault_auth_backend" "auth_kubernetes" {
  type = "kubernetes"
  path = "k8s-${var.Cluster}-${var.Color}"
  tune {
    max_lease_ttl = "3628800s"
  }
  depends_on = [
    null_resource.auth_kubernetes_disable,
    helm_release.vault
  ]
}

data "vault_generic_secret" "cluster_token" {
  path       = "secret/kubernetes-${var.Cluster}-${var.Color}"
  depends_on = [vault_generic_secret.cluster_token]
}

resource "vault_kubernetes_auth_backend_config" "auth_kubernetes" {
  backend            = "k8s-${var.Cluster}-${var.Color}"
  kubernetes_host    = data.vault_generic_secret.cluster_token.data["HOST"]
  kubernetes_ca_cert = data.kubernetes_secret.vault.data["ca.crt"]
  token_reviewer_jwt = data.kubernetes_secret.vault.data["token"]
  # issuer                 = "kubernetes/serviceaccount"
  disable_local_ca_jwt   = "true"
  disable_iss_validation = "true"
  depends_on = [
    vault_auth_backend.auth_kubernetes,
    vault_generic_secret.cluster_token
  ]
}
resource "vault_kubernetes_auth_backend_role" "role_tekton" {
  backend                          = "k8s-${var.Cluster}-${var.Color}"
  role_name                        = "tekton"
  bound_service_account_names      = ["default"]
  bound_service_account_namespaces = ["tekton-pipelines", "tekton-tasks"]
  token_ttl                        = 0
  token_policies                   = ["tekton"]
  depends_on = [
    vault_kubernetes_auth_backend_config.auth_kubernetes,
    vault_auth_backend.auth_kubernetes
  ]
}

resource "vault_kubernetes_auth_backend_role" "role_cert-manager" {
  backend                          = "k8s-${var.Cluster}-${var.Color}"
  role_name                        = "cert-manager"
  bound_service_account_names      = ["${var.Cluster}-cert-manager"]
  bound_service_account_namespaces = ["kube-system"]
  token_ttl                        = 0
  token_policies                   = ["pki"]
  depends_on = [
    vault_kubernetes_auth_backend_config.auth_kubernetes,
    vault_auth_backend.auth_kubernetes
  ]
}

