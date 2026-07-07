resource "zpa_policy_timeout_rule" "reauth" {
  name                = "${local.prefix}-reauth-timeout"
  description         = "Reauthentication timeout for ${local.idp_name} and ${local.prefix} application groups"
  action              = "RE_AUTH"
  reauth_timeout      = local.timeout_policy.reauth_timeout
  reauth_idle_timeout = local.timeout_policy.reauth_idle_timeout
  operator            = "AND"

  conditions {
    operator = "OR"

    operands {
      object_type = "IDP"
      lhs         = "id"
      rhs         = data.zpa_idp_controller.policy.id
    }
  }

  conditions {
    operator = "OR"

    dynamic "operands" {
      for_each = local.segment_groups
      iterator = group

      content {
        object_type = "APP_GROUP"
        lhs         = "id"
        rhs         = zpa_segment_group.group[group.value].id
      }
    }
  }

  depends_on = [
    zpa_segment_group.group
  ]
}
