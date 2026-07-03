module "zscaler_api" {
  source = "../../../terraform-modules/zscaler-api"

  Config_infra        = local.zscaler_private_infra
  Config_app_policies = local.zscaler_app_policies
  Prefix              = "sandbox"
}
