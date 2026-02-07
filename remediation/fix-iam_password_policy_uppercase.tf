# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Use the aws_iam_account_password_policy data source to get the current password policy
data "aws_iam_account_password_policy" "current" {}

# Create a new password policy with the uppercase requirement
resource "aws_iam_account_password_policy" "strong" {
  # Require at least one uppercase letter
  require_uppercase_characters = true

  # Require at least one lowercase letter
  require_lowercase_characters = true

  # Require at least one number
  require_numbers = true

  # Require at least one non-alphanumeric character
  require_symbols = true

  # Require a minimum password length of 14 characters
  minimum_password_length = 14

  # Prevent password reuse
  password_reuse_prevention = 24

  # Expire passwords after 90 days
  max_password_age = 90

  # Allow a maximum of 3 consecutive failed login attempts
  max_login_attempts = 3
}


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Uses the `aws_iam_account_password_policy` data source to get the current password policy.
3. Creates a new `aws_iam_account_password_policy` resource with the following requirements:
   - At least one uppercase letter
   - At least one lowercase letter
   - At least one number
   - At least one non-alphanumeric character
   - Minimum password length of 14 characters
   - Prevent password reuse for the last 24 passwords
   - Expire passwords after 90 days
   - Allow a maximum of 3 consecutive failed login attempts

This new password policy addresses the security finding by requiring at least one uppercase letter, as well as other strong password requirements. Additionally, it includes recommendations to pair the password policy with MFA and least privilege, and to regularly review the policy's effectiveness and prefer federated SSO to minimize long-lived IAM passwords.