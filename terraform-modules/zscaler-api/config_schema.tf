variable "Config_infra" {
  type = object({
    defaults = object({
      server_group  = string
      segment_group = string
      tcp_port_range = list(object({
        from = string
        to   = string
      }))
      udp_port_range = list(object({
        from = string
        to   = string
      }))
    })

    timeout_policy = object({
      reauth_timeout_hours      = number
      reauth_idle_timeout_hours = number
    })

    app_connector_groups = map(object({
      city_country = string
      country_code = string
      latitude     = string
      longitude    = string
      location     = string
    }))

    server_groups = map(object({
      app_connector_group = string
    }))

    segment_groups = list(string)

    provisioning_keys = object({
      enrollment_cert_name = string
      vault_path           = string
      keys = map(object({
        name                = string
        app_connector_group = string
        association_type    = string
        max_usage           = string
      }))
    })

    applications = map(object({
      domain        = string
      server_group  = optional(string)
      segment_group = optional(string)
      tcp_port_range = optional(list(object({
        from = string
        to   = string
      })))
      udp_port_range = optional(list(object({
        from = string
        to   = string
      })))
    }))
  })

  validation {
    condition = alltrue([
      for app_name, _ in var.Config_infra.applications :
      length(regexall("^[0-9A-Za-z._-]+$", app_name)) > 0
    ])

    error_message = "Application names may only contain letters, numbers, periods, hyphens, and underscores."
  }

  validation {
    condition = (
      var.Config_infra.timeout_policy.reauth_timeout_hours >= -1 &&
      var.Config_infra.timeout_policy.reauth_idle_timeout_hours >= -1
    )

    error_message = "timeout_policy reauth_timeout_hours and reauth_idle_timeout_hours must be greater than or equal to -1. For reauth_timeout_hours, -1 means never reauthenticate. For reauth_idle_timeout_hours, -1 means use the ZPA default idle timeout."
  }

  validation {
    condition = contains(
      keys(var.Config_infra.server_groups),
      var.Config_infra.defaults.server_group
    )

    error_message = "defaults.server_group must reference a defined server group."
  }

  validation {
    condition = alltrue([
      for _, app in var.Config_infra.applications :
      contains(
        keys(var.Config_infra.server_groups),
        app.server_group == null ? var.Config_infra.defaults.server_group : app.server_group
      )
    ])

    error_message = "Every application server_group must reference a defined server group."
  }

  validation {
    condition = contains(
      var.Config_infra.segment_groups,
      var.Config_infra.defaults.segment_group
    )

    error_message = "defaults.segment_group must reference a defined segment group."
  }

  validation {
    condition = alltrue([
      for _, app in var.Config_infra.applications :
      contains(
        var.Config_infra.segment_groups,
        app.segment_group == null ? var.Config_infra.defaults.segment_group : app.segment_group
      )
    ])

    error_message = "Every application segment_group must reference a defined segment group."
  }

  validation {
    condition = alltrue([
      for _, server_group in var.Config_infra.server_groups :
      (
        server_group.app_connector_group != ""
        && contains(keys(var.Config_infra.app_connector_groups), server_group.app_connector_group)
      )
    ])

    error_message = "Every server group app_connector_group must reference a defined app connector group."
  }

  validation {
    condition = alltrue([
      for _, provisioning_key in var.Config_infra.provisioning_keys.keys :
      (
        provisioning_key.app_connector_group != ""
        && contains(keys(var.Config_infra.app_connector_groups), provisioning_key.app_connector_group)
      )
    ])

    error_message = "Every provisioning key app_connector_group must reference a defined app connector group."
  }
}

variable "Config_app_policies" {
  type = map(object({
    scim_groups = list(string)
    apps        = optional(list(string), [])
    groups      = optional(list(string), [])
  }))

  validation {
    condition = alltrue([
      for _, policy in var.Config_app_policies :
      length(policy.scim_groups) > 0 && alltrue([
        for group_name in policy.scim_groups :
        group_name != ""
      ])
    ])

    error_message = "Every access policy must define at least one scim_groups entry."
  }

  validation {
    condition = alltrue([
      for _, policy in var.Config_app_policies :
      length(policy.apps) + length(policy.groups) > 0
    ])

    error_message = "Every access policy must define at least one apps or groups entry."
  }

  validation {
    condition = alltrue([
      for _, policy in var.Config_app_policies :
      alltrue([
        for app_name in policy.apps :
        app_name != ""
        ]) && alltrue([
        for group_name in policy.groups :
        group_name != ""
      ])
    ])

    error_message = "Access policy apps and groups entries cannot be empty."
  }
}

terraform {
  required_providers {
    vault = {
      source = "hashicorp/vault"
    }
    zpa = {
      source = "zscaler/zpa"
    }
  }
}
