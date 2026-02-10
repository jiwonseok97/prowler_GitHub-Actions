# Ensure the AWS account is part of an AWS Organization with all features enabled
resource "aws_organizations_organization" "remediation_organization" {
  aws_service_access_principals = [
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
    "delivery.logs.amazonaws.com",
    "guardduty.amazonaws.com",
    "inspector.amazonaws.com",
    "macie.amazonaws.com",
    "ram.amazonaws.com",
    "servicecatalog.amazonaws.com",
    "ssm.amazonaws.com",
  ]
  enabled_policy_types = [
    "SERVICE_CONTROL_POLICY",
    "TAG_POLICY",
  ]
  feature_set = "ALL"
}

# Create an Organizational Unit (OU) for management accounts
resource "aws_organizations_organizational_unit" "remediation_management_ou" {
  name      = "Management"
  parent_id = aws_organizations_organization.remediation_organization.roots[0].id
}

# Create an Organizational Unit (OU) for member accounts
resource "aws_organizations_organizational_unit" "remediation_member_ou" {
  name      = "Members"
  parent_id = aws_organizations_organization.remediation_organization.roots[0].id
}

# Create a Service Control Policy (SCP) to enforce least privilege
resource "aws_organizations_policy" "remediation_least_privilege_scp" {
  content = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Deny",
        "Action" : "*",
        "Resource" : "*"
      }
    ]
  })
  name        = "Least Privilege SCP"
  description = "Deny all actions by default, enforce least privilege"
}

# Attach the SCP to the Member OU
resource "aws_organizations_policy_attachment" "remediation_least_privilege_scp_attachment" {
  policy_id = aws_organizations_policy.remediation_least_privilege_scp.id
  target_id = aws_organizations_organizational_unit.remediation_member_ou.id
}

# Enable CloudTrail for the organization
resource "aws_cloudtrail" "remediation_cloudtrail" {
  name                          = "remediation-cloudtrail"
  s3_bucket_name                = aws_s3_bucket.remediation_cloudtrail_bucket.id
  s3_key_prefix                 = "cloudtrail"
  is_multi_region_trail         = true
  include_global_service_events = true
  enable_log_file_validation    = true
}

# Create an S3 bucket for CloudTrail logs
resource "aws_s3_bucket" "remediation_cloudtrail_bucket" {
  bucket = "remediation-cloudtrail-logs"

}

# Centralize billing for the organization
resource "aws_organizations_account" "remediation_master_account" {
  name  = "Remediation Master Account"
  email = "remediation-master@example.com"
  role_name = "OrganizationAccountAccessRole"
}