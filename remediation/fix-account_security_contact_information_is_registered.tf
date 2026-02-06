# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Get the current AWS account ID
data "aws_caller_identity" "current" {}

# Create an AWS IAM account alias
resource "aws_iam_account_alias" "security_alias" {
  # Use a monitored alias (e.g., `security@domain`)
  account_alias = "security@example.com"
}

# Create an AWS IAM contact for security-related issues
resource "aws_iam_account_password_policy" "security_contact" {
  # Apply to every account (prefer Org-wide automation)
  account_id = data.aws_caller_identity.current.account_id

  # Use a monitored team phone number
  contact_email = "security@example.com"
  contact_phone = "+1-555-1234567"
}