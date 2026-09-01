
data "vault_auth_backend" "kubernetes" {
  path = "k8s-${var.Cluster}-${var.Color}"
}



resource "vault_kubernetes_auth_backend_role" "harbor_role" {
  for_each                         = local.assignVaultPolicy
  backend                          = data.vault_auth_backend.kubernetes.path
  role_name                        = each.key
  bound_service_account_names      = ["default"]
  bound_service_account_namespaces = [each.key]
  token_ttl                        = 3600
  token_policies                   = flatten(each.value)
}

resource "vault_kubernetes_auth_backend_role" "dome_role" {
  count                            = local.appSpecificVaultRoles
  backend                          = data.vault_auth_backend.kubernetes.path
  role_name                        = "dome"
  bound_service_account_names      = ["default"]
  bound_service_account_namespaces = ["dome-*"]
  token_ttl                        = 3600
  token_policies                   = ["dome"]
}
resource "vault_kubernetes_auth_backend_role" "minion_role" {
  count                            = local.appSpecificVaultRoles
  backend                          = data.vault_auth_backend.kubernetes.path
  role_name                        = "minion"
  bound_service_account_names      = ["default"]
  bound_service_account_namespaces = ["minion-*"]
  token_ttl                        = 3600
  token_policies                   = ["minion"]
}
resource "vault_kubernetes_auth_backend_role" "paste" {
  count                            = local.appSpecificVaultRoles
  backend                          = data.vault_auth_backend.kubernetes.path
  role_name                        = "paste"
  bound_service_account_names      = ["default"]
  bound_service_account_namespaces = ["paste-*"]
  token_ttl                        = 3600
  token_policies                   = ["paste"]
}
