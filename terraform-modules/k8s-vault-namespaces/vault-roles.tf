
data "vault_auth_backend" "kubernetes" {
  path = "k8s-sandbox-green"
}

resource "vault_policy" "harbor" {
  name = "harbor"

  policy = <<EOT
path "secret/minio/users" {
  capabilities = ["read","list"]
}
EOT
}


resource "vault_kubernetes_auth_backend_role" "harbor_role" {
  backend                          = data.vault_auth_backend.kubernetes.path
  role_name                        = "harbor"
  bound_service_account_names      = ["default"]
  bound_service_account_namespaces = ["harbor"]
  token_ttl                        = 3600
  token_policies                   = ["harbor"]
}
