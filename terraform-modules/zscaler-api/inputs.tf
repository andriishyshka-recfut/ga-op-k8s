locals {
  defaults             = var.Config_infra.defaults
  app_connector_groups = var.Config_infra.app_connector_groups
  applications         = var.Config_infra.applications
  server_groups        = var.Config_infra.server_groups
  segment_groups       = toset(var.Config_infra.segment_groups)
  provisioning_keys    = var.Config_infra.provisioning_keys
  access_policies      = var.Config_app_policies
  idp_name             = "GEM_ZPA_Users"

  application_segments = {
    for app_name, app in local.applications :
    app_name => {
      name           = app_name
      policies       = app.policies
      domain_names   = [app.domain]
      server_group   = app.server_group == null ? local.defaults.server_group : app.server_group
      segment_group  = app.segment_group == null ? local.defaults.segment_group : app.segment_group
      tcp_port_range = app.tcp_port_range == null ? local.defaults.tcp_port_range : app.tcp_port_range
      udp_port_range = app.udp_port_range == null ? local.defaults.udp_port_range : app.udp_port_range
    }
  }

  used_access_policy_names = toset(flatten([
    for app in values(local.application_segments) :
    app.policies
  ]))

  missing_access_policies = setsubtract(
    local.used_access_policy_names,
    toset(keys(local.access_policies))
  )

  access_policy_rules = {
    for policy_name, policy in local.access_policies :
    policy_name => {
      scim_groups = toset(policy.scim_groups)
      applications = toset([
        for app_name, app in local.application_segments :
        app_name if contains(app.policies, policy_name)
      ])
    }
    if contains(local.used_access_policy_names, policy_name)
  }

  used_scim_groups = toset(flatten([
    for policy in values(local.access_policy_rules) :
    tolist(policy.scim_groups)
  ]))

  access_policy_config_valid = (
    length(local.missing_access_policies) == 0
  )
}
