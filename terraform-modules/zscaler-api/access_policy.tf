resource "terraform_data" "validate_access_policies" {
  input = {
    missing_policy_apps                = local.missing_policy_apps
    missing_policy_groups              = local.missing_policy_groups
    policies_without_targets           = local.policies_without_targets
    applications_without_access_policy = local.applications_without_access_policy
  }

  lifecycle {
    precondition {
      condition     = local.access_policy_config_valid
      error_message = "Invalid access policy config. Undefined policy apps: ${join(", ", tolist(local.missing_policy_apps))}; undefined policy groups: ${join(", ", tolist(local.missing_policy_groups))}; policies without targets: ${join(", ", tolist(local.policies_without_targets))}; applications without access policy: ${join(", ", tolist(local.applications_without_access_policy))}"
    }
  }
}

data "zpa_idp_controller" "policy" {
  name = local.idp_name
}

data "zpa_scim_groups" "policy" {
  for_each = local.used_scim_groups

  name     = each.key
  idp_name = local.idp_name
}

resource "zpa_policy_access_rule" "rule" {
  for_each = local.access_policy_rules

  name     = "${local.prefix}-${each.key}"
  action   = "ALLOW"
  operator = "AND"

  conditions {
    operator = "OR"

    dynamic "operands" {
      for_each = each.value.apps
      iterator = app

      content {
        object_type = "APP"
        lhs         = "id"
        rhs         = zpa_application_segment.segment[app.value].id
      }
    }

    dynamic "operands" {
      for_each = each.value.groups
      iterator = group

      content {
        object_type = "APP_GROUP"
        lhs         = "id"
        rhs         = zpa_segment_group.group[group.value].id
      }
    }
  }

  conditions {
    operator = "OR"

    dynamic "operands" {
      for_each = each.value.scim_groups

      content {
        object_type = "SCIM_GROUP"
        lhs         = data.zpa_idp_controller.policy.id
        rhs         = data.zpa_scim_groups.policy[operands.value].id
      }
    }
  }

  depends_on = [
    terraform_data.validate_access_policies,
    zpa_application_segment.segment,
    zpa_segment_group.group
  ]
}
