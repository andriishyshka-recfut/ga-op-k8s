
data "vault_auth_backend" "kubernetes" {
  path = "k8s-sandbox-green"
}



resource "vault_kubernetes_auth_backend_role" "harbor_role" {
  for_each                         = local.assignVaultPolicy
  backend                          = data.vault_auth_backend.kubernetes.path
  role_name                        = "harbor"
  bound_service_account_names      = ["default"]
  bound_service_account_namespaces = [each.key]
  token_ttl                        = 3600
  token_policies                   = flatten(each.value)
}
