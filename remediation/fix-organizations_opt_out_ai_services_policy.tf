# AI Services Opt-Out Policy for AWS Organization
data "aws_organizations_organization" "current" {}

resource "aws_organizations_policy" "remediation_ai_opt_out" {
  name        = "ai-services-opt-out"
  description = "Opt out of all AWS AI services data usage"
  type        = "AISERVICES_OPT_OUT_POLICY"

  content = jsonencode({
    services = {
      "@@operators_allowed_for_child_policies" = ["@@none"]
      default = {
        "@@operators_allowed_for_child_policies" = ["@@none"]
        opt_out_policy = {
          "@@assign" = "optOut"
        }
      }
    }
  })
}

resource "aws_organizations_policy_attachment" "remediation_ai_opt_out" {
  policy_id = aws_organizations_policy.remediation_ai_opt_out.id
  target_id = data.aws_organizations_organization.current.roots[0].id
}
