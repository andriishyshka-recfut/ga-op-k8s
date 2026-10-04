
locals {
  additional_providers_path = "${get_terragrunt_dir()}/additional_providers.hcl"
  additional_providers_check = can(read_terragrunt_config(local.additional_providers_path)) ? read_terragrunt_config(local.additional_providers_path) : null
  additional_providers = local.additional_providers_check != null && can(local.additional_providers_check.locals.additional_providers) ? local.additional_providers_check.locals.additional_providers : []
  default_state_name = element(split("/", get_terragrunt_dir()), length(split("/", get_terragrunt_dir())) - 1)
  state_config_path = "${get_terragrunt_dir()}/state.hcl"
  terraform_state_name = fileexists(local.state_config_path) ? read_terragrunt_config(local.state_config_path).locals.terraform_state_name : local.default_state_name
  prepare_artifactory_mtls = contains(local.additional_providers, "artifactory_mtls") && get_env("TF_VAR_RuntimeContext", "local") == "tekton"
}
terraform {
  before_hook "prepare_artifactory_mtls" {
    commands = ["plan", "apply"]

    execute = local.prepare_artifactory_mtls? [
      "sh",
      "-c",
      "terragrunt --working-dir '${get_parent_terragrunt_dir()}/terraform-modules/k8s-vault-artifactory-mtls' apply -auto-approve"
    ] : ["true"]
  }
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

errors {
  retry "transient_errors" {
    retryable_errors     = ["isn't valid for cluster, check the APIVersion and Kind fields are valid","'dict object' has no .* attribute 'status'","Provider produced inconsistent final plan","Failed to resolve provider packages"]
    max_attempts         = 3
    sleep_interval_sec   = 5
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents = templatefile("terragrunt.tftpl",{additional_providers = local.additional_providers, dir = "${local.terraform_state_name}-state", path = local.additional_providers_path})
}

