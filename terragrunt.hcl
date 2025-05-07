
locals {
  additional_providers_path = "${get_terragrunt_dir()}/additional_providers.hcl"
  additional_providers_check = can(read_terragrunt_config(local.additional_providers_path)) ? read_terragrunt_config(local.additional_providers_path) : null
  additional_providers = local.additional_providers_check != null && can(local.additional_providers_check.locals.additional_providers) ? local.additional_providers_check.locals.additional_providers : []
}
terraform {

  extra_arguments "custom_vars" {
    commands = [
      "init",
      "apply",
      "plan",
      "import",
      "push",
      "destroy",
      "refresh"
    ]

    required_var_files = ["${get_parent_terragrunt_dir()}/${get_env("CONF_PATH")}"]
  }
}

retryable_errors = [
  "isn't valid for cluster, check the APIVersion and Kind fields are valid",
  "'dict object' has no .* attribute 'status'",
  "Provider produced inconsistent final plan"
]

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents = templatefile("terragrunt.tftpl",{additional_providers = local.additional_providers, dir = "${element(split("/", get_terragrunt_dir()), length(split("/", get_terragrunt_dir())) - 1)}-state", path = local.additional_providers_path})
}

