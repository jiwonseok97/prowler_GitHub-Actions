# AWS Organizations AI services opt-out policy
# Opts out of all AI service data usage for the organization

resource "aws_organizations_policy" "remediation_ai_opt_out" {
  name        = "remediation-ai-services-opt-out"
  description = "Opt out of AWS AI services using organizational data"
  type        = "AISERVICES_OPT_OUT_POLICY"
  content = jsonencode({
    services = {
      "@@operators_allowed_for_child_policies" = ["@@none"]
      default = {
        "@@operators_allowed_for_child_policies" = ["@@none"]
        opt_out_policy = {
          "@@operators_allowed_for_child_policies" = ["@@none"]
          "@@assign"                               = "optOut"
        }
      }
    }
  })
}

resource "aws_organizations_policy_attachment" "remediation_ai_opt_out_attachment" {
  policy_id = aws_organizations_policy.remediation_ai_opt_out.id
  target_id = data.aws_organizations_organization.current.roots[0].id
}

data "aws_organizations_organization" "current" {}
