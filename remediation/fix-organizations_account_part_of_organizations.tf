# Create a new AWS Organization
resource "aws_organizations_organization" "remediation_organization" {
  aws_service_access_principals = ["cloudtrail.amazonaws.com", "config.amazonaws.com", "guardduty.amazonaws.com", "securityhub.amazonaws.com"]
  enabled_policy_types          = ["SERVICE_CONTROL_POLICY"]
}

# Create a new Organizational Unit (OU) for management accounts
resource "aws_organizations_organizational_unit" "remediation_management_ou" {
  name      = "Management"
  parent_id = aws_organizations_organization.remediation_organization.roots[0].id
}

# Create a new Organizational Unit (OU) for member accounts
resource "aws_organizations_organizational_unit" "remediation_member_ou" {
  name      = "Members"
  parent_id = aws_organizations_organization.remediation_organization.roots[0].id
}

# Create a new Service Control Policy (SCP) for least privilege
resource "aws_organizations_policy" "remediation_least_privilege_scp" {
  name        = "Least Privilege SCP"
  description = "Enforce least privilege access for member accounts"
  content     = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Deny",
        Action = "*",
        Resource = "*"
      }
    ]
  })
}

# Attach the Least Privilege SCP to the Member OU
resource "aws_organizations_policy_attachment" "remediation_least_privilege_scp_attachment" {
  policy_id = aws_organizations_policy.remediation_least_privilege_scp.id
  target_id = aws_organizations_organizational_unit.remediation_member_ou.id
}

# Create a new management account and move it to the Management OU
resource "aws_organizations_account" "remediation_management_account" {
  name  = "Management Account"
  email = "management@example.com"

  parent_id = aws_organizations_organizational_unit.remediation_management_ou.id
}

# Create a new member account and move it to the Member OU
resource "aws_organizations_account" "remediation_member_account" {
  name  = "Member Account"
  email = "member@example.com"

  parent_id = aws_organizations_organizational_unit.remediation_member_ou.id
}