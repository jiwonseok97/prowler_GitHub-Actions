# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Use the aws_iam_account_password_policy data source to get the current password policy
data "aws_iam_account_password_policy" "current" {}

# Create a new IAM password policy with the required settings
resource "aws_iam_account_password_policy" "enhanced" {
  # Require at least one uppercase letter
  require_uppercase_characters = true
  # Require at least one lowercase letter
  require_lowercase_characters = true
  # Require at least one number
  require_numbers = true
  # Require at least one non-alphanumeric character
  require_symbols = true
  # Minimum password length
  minimum_password_length = 14
  # Prevent password reuse for the last 24 passwords
  password_reuse_prevention = 24
  # Expire passwords after 90 days
  max_password_age = 90
  # Allow users to change their own passwords
  allow_users_to_change_password = true
}


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Uses the `aws_iam_account_password_policy` data source to get the current password policy.
3. Creates a new `aws_iam_account_password_policy` resource with the following settings:
   - Requires at least one uppercase letter, one lowercase letter, one number, and one non-alphanumeric character.
   - Sets the minimum password length to 14 characters.
   - Prevents the reuse of the last 24 passwords.
   - Expires passwords after 90 days.
   - Allows users to change their own passwords.

This should address the security finding by ensuring that the IAM password policy prevents the reuse of the last 24 passwords, as recommended.