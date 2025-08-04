terraform {

  extra_arguments "custom_vars" {
    commands = [
      "init",
      "apply",
      "plan",
      "import",
      "push",
      "refresh",
      "destroy"
    ]

    required_var_files = ["${get_parent_terragrunt_dir()}/../../../../${get_env("CONF_PATH")}"]
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents = templatefile("${get_parent_terragrunt_dir()}/../../../../terragrunt-cluster.tftpl",
    { 
      Color = get_env("TF_VAR_Color")
      Cluster = get_env("CLUSTER")
      Vault = get_env("VAULT_ADDR")
      Bucket = "terraform-state-222"
      Folder = basename(get_terragrunt_dir())
    }
  )
}