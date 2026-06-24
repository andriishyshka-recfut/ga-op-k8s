resource "terraform_data" "validate_access_policies" {
  input = {
    missing_access_policies = local.missing_access_policies
  }

  lifecycle {
    precondition {
      condition     = local.access_policy_config_valid
      error_message = "Invalid access policy config. Undefined policies: ${join(", ", tolist(local.missing_access_policies))}"
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

  name     = each.key
  action   = "ALLOW"
  operator = "AND"

  conditions {
    operator = "OR"

    dynamic "operands" {
      for_each = each.value.applications

      content {
        object_type = "APP"
        lhs         = "id"
        rhs         = zpa_application_segment.segment[operands.value].id
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
    zpa_application_segment.segment
  ]
}
