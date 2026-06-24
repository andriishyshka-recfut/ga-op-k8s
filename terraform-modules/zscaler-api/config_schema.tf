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
      domain         = string
      server_group   = optional(string)
      segment_group  = optional(string)
      policies       = list(string)
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
      for _, app in var.Config_infra.applications :
      length(app.policies) > 0
    ])

    error_message = "Every application must define at least one policy."
  }

  validation {
    condition = alltrue([
      for app_name, _ in var.Config_infra.applications :
      length(regexall("^[0-9A-Za-z._-]+$", app_name)) > 0
    ])

    error_message = "Application names may only contain letters, numbers, periods, hyphens, and underscores."
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
