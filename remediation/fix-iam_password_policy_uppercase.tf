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

  # Prevent password changes for 24 hours after creation
  hard_expiry = true
}


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Uses the `aws_iam_account_password_policy` data source to get the current password policy.
3. Creates a new password policy resource with the following requirements:
   - At least one uppercase letter
   - At least one lowercase letter
   - At least one number
   - At least one non-alphanumeric character
   - Minimum password length of 14 characters
   - Prevent password reuse for the last 24 passwords
   - Expire passwords after 90 days
   - Prevent password changes for 24 hours after creation

This new password policy should address the "IAM password policy requires at least one uppercase letter" security finding and implement a stronger password policy as recommended.