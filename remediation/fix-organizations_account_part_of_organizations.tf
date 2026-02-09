# Create AWS Organization with security service integrations
resource "aws_organizations_organization" "remediation_organization" {
  aws_service_access_principals = [
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
    "guardduty.amazonaws.com",
    "securityhub.amazonaws.com"
  ]
  enabled_policy_types = [
    "SERVICE_CONTROL_POLICY",
    "AISERVICES_OPT_OUT_POLICY"
  ]
  feature_set = "ALL"
}
