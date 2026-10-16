variable "Config" {
  description = "MongoDB dynamic credential configuration decoded from JSON."
  type = object({
    defaults = object({
      default_ttl_seconds = number
      max_ttl_seconds     = number
    })
    applications = map(object({
      default_ttl_seconds = optional(number)
      max_ttl_seconds     = optional(number)
      databases = map(object({
        role_type = optional(string)
        collections = optional(map(object({
          role_type = string
        })), {})
      }))
    }))
  })

  validation {
    condition = length(var.Config.applications) > 0 && alltrue([
      for application in var.Config.applications :
      length(application.databases) > 0
    ])

    error_message = "Config must contain at least one application and every application must contain at least one database."
  }

  validation {
    condition = alltrue([
      for application_name in keys(var.Config.applications) :
      can(regex("^[A-Za-z0-9_-]+$", application_name))
    ])

    error_message = "Application names may contain only letters, digits, underscores, and hyphens."
  }

  validation {
    condition = (
      var.Config.defaults.default_ttl_seconds > 0 &&
      var.Config.defaults.max_ttl_seconds > 0 &&
      var.Config.defaults.default_ttl_seconds <= var.Config.defaults.max_ttl_seconds
    )

    error_message = "Default TTL values must be positive numbers and default_ttl_seconds must not exceed max_ttl_seconds."
  }

  validation {
    condition = alltrue([
      for application in var.Config.applications :
      coalesce(application.default_ttl_seconds, var.Config.defaults.default_ttl_seconds) > 0 &&
      coalesce(application.max_ttl_seconds, var.Config.defaults.max_ttl_seconds) > 0 &&
      coalesce(application.default_ttl_seconds, var.Config.defaults.default_ttl_seconds) <=
      coalesce(application.max_ttl_seconds, var.Config.defaults.max_ttl_seconds)
    ])

    error_message = "Effective application TTL values must be positive numbers and default_ttl_seconds must not exceed max_ttl_seconds."
  }

  validation {
    condition = alltrue(flatten([
      for application in var.Config.applications : [
        for access in application.databases :
        (access.role_type != null) != (length(access.collections) > 0)
      ]
    ]))

    error_message = "Every database entry must define exactly one of role_type or a non-empty collections map."
  }

  validation {
    condition = alltrue(flatten([
      for application in var.Config.applications : [
        for access in application.databases :
        access.role_type == null || contains(["read", "readWrite"], access.role_type)
      ]
    ]))

    error_message = "Each database role_type must be read or readWrite."
  }

  validation {
    condition = alltrue(flatten([
      for application in var.Config.applications : [
        for access in application.databases : [
          for collection in access.collections :
          contains(["read", "readWrite"], collection.role_type)
        ]
      ]
    ]))

    error_message = "Each collection role_type must be read or readWrite."
  }

  validation {
    condition = alltrue(flatten([
      for application in var.Config.applications : [
        for database_name, access in application.databases :
        database_name != "" && alltrue([
          for collection_name in keys(access.collections) :
          collection_name != ""
        ])
      ]
    ]))

    error_message = "Database and collection names must not be empty."
  }
}
