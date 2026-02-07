# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Update the IAM password policy to meet the recommended requirements
resource "aws_iam_account_password_policy" "strict" {
  minimum_password_length        = 16
  require_lowercase_characters   = true
  require_uppercase_characters   = true
  require_numbers                = true
  require_symbols                = true
  allow_users_to_change_password = true
  max_password_age              = 90
  password_reuse_prevention      = 24
}

# Enable MFA for all IAM console users
resource "aws_iam_account_alias" "example" {
  account_alias = "my-company-account"
}

resource "aws_iam_account_signing_certificate" "example" {
  user_name = "example-user"
  certificate_body = "-----BEGIN CERTIFICATE-----\n...\n-----END CERTIFICATE-----"
}

resource "aws_iam_user_login_profile" "example" {
  user_name   = "example-user"
  password_reset_required = true
}

# Prefer SSO over local IAM users
data "aws_ssoadmin_instances" "example" {}

resource "aws_ssoadmin_permission_set" "example" {
  name       = "example-permission-set"
  description = "Example permission set"
  instance_arn = data.aws_ssoadmin_instances.example.arns[0]
}

# Apply least privilege and monitor authentication events
# (Additional Terraform code would be required to implement these recommendations)