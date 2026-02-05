terraform {

  extra_arguments "custom_vars" {
    commands = [
      "init",
      "apply",
      "plan",
      "import",
      "push",
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
