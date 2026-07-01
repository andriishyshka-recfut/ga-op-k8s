variable "Settings" {}
variable "Cluster" {}
variable "VaultAddress" {}

locals {
  zscaler_private_infra = merge(
    jsondecode(file("${path.module}/private_infra.json")),
    jsondecode(file("${path.module}/apps.json"))
  )
  zscaler_app_policies  = jsondecode(file("${path.module}/app_policies.json"))
  zpa_client_id         = data.vault_generic_secret.zscaler_api.data["client_id"]
  zpa_client_secret     = sensitive(data.vault_generic_secret.zscaler_api.data["key"])
  zpa_customer_id       = data.vault_generic_secret.zscaler_api.data["customer_id"]
  zpa_api_vault_path    = "secret/misc/zscaler/api"
}

data "vault_generic_secret" "zscaler_api" {
  path = local.zpa_api_vault_path
}
