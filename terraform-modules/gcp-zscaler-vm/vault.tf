resource "vault_gcp_auth_backend" "zscaler" {
  count = local.zscaler_enabled ? 1 : 0

  path = "gcp-zscaler"

  credentials = local.create_service_account_key ? base64decode(google_service_account_key.vm[0].private_key) : null
}

resource "vault_gcp_auth_backend_role" "zscaler_vm" {
  count = local.zscaler_enabled ? 1 : 0

  backend                = vault_gcp_auth_backend.zscaler[0].path
  role                   = "zscaler-vm"
  type                   = "gce"
  bound_projects         = [local.gcp_project]
  bound_zones            = [local.zone]
  bound_service_accounts = [google_service_account.vm.email]
  token_policies         = ["zscaler-vm"]
}
