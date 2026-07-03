variable "Prefix" {}
locals {
  defaults             = var.Config_infra.defaults
  app_connector_groups = var.Config_infra.app_connector_groups
  applications         = var.Config_infra.applications
  server_groups        = var.Config_infra.server_groups
  segment_groups       = toset(var.Config_infra.segment_groups)
  provisioning_keys    = var.Config_infra.provisioning_keys
  access_policies      = var.Config_app_policies
  idp_name             = "GEM_ZPA_Users"
  prefix               = var.Prefix

  application_segments = {
    for app_name, app in local.applications :
    app_name => {
      name           = app_name
      domain_names   = split(",",app.domain) 
      server_group   = app.server_group == null ? local.defaults.server_group : app.server_group
      segment_group  = app.segment_group == null ? local.defaults.segment_group : app.segment_group
      tcp_port_range = app.tcp_port_range == null ? local.defaults.tcp_port_range : app.tcp_port_range
      udp_port_range = app.udp_port_range == null ? local.defaults.udp_port_range : app.udp_port_range
    }
  }

  policy_app_names = toset(flatten([
    for policy in values(local.access_policies) :
    policy.apps
  ]))

  policy_group_names = toset(flatten([
    for policy in values(local.access_policies) :
    policy.groups
  ]))

  missing_policy_apps = setsubtract(
    local.policy_app_names,
    toset(keys(local.application_segments))
  )

  missing_policy_groups = setsubtract(
    local.policy_group_names,
    local.segment_groups
  )

  access_policy_targets = {
    for policy_name, policy in local.access_policies :
    policy_name => {
      scim_groups = toset(policy.scim_groups)
      apps = toset([
        for app_name in policy.apps :
        app_name if contains(keys(local.application_segments), app_name)
      ])
      groups = toset([
        for group_name in policy.groups :
        group_name if contains(tolist(local.segment_groups), group_name)
      ])
    }
  }

  access_policy_rules = {
    for policy_name, policy in local.access_policy_targets :
    policy_name => policy if length(policy.apps) + length(policy.groups) > 0
  }

  policies_without_targets = setsubtract(
    toset(keys(local.access_policies)),
    toset(keys(local.access_policy_rules))
  )

  applications_with_access_policy = toset(concat(
    [
      for app_name in local.policy_app_names :
      app_name if contains(keys(local.application_segments), app_name)
    ],
    flatten([
      for policy in values(local.access_policies) : [
        for app_name, app in local.application_segments :
        app_name if contains(policy.groups, app.segment_group)
      ]
    ])
  ))

  applications_without_access_policy = setsubtract(
    toset(keys(local.application_segments)),
    local.applications_with_access_policy
  )

  used_scim_groups = toset(flatten([
    for policy in values(local.access_policy_rules) :
    tolist(policy.scim_groups)
  ]))

  access_policy_config_valid = (
    length(local.missing_policy_apps) == 0 &&
    length(local.missing_policy_groups) == 0 &&
    length(local.policies_without_targets) == 0 &&
    length(local.applications_without_access_policy) == 0
  )
}
