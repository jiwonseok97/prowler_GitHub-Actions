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

  # Set the maximum password age to 90 days
  max_password_age = 90
}


The provided Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Uses the `aws_iam_account_password_policy` data source to get the current password policy.
3. Creates a new `aws_iam_account_password_policy` resource with the following requirements:
   - Requires at least one uppercase letter
   - Requires at least one lowercase letter
   - Requires at least one number
   - Requires at least one non-alphanumeric character
   - Requires a minimum password length of 14 characters
   - Prevents password reuse for the last 24 passwords
   - Sets the maximum password age to 90 days

This should address the security finding by enforcing a strong password policy that includes the uppercase letter requirement.