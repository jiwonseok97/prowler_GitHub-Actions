# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Use the aws_iam_account_password_policy data source to get the current password policy
data "aws_iam_account_password_policy" "current" {}

# Create a new IAM password policy with the required symbol character
resource "aws_iam_account_password_policy" "enhanced" {
  # Require at least one non-alphanumeric character
  require_symbols = true

  # Inherit other settings from the current password policy
  minimum_password_length        = data.aws_iam_account_password_policy.current.minimum_password_length
  require_lowercase_characters   = data.aws_iam_account_password_policy.current.require_lowercase_characters
  require_uppercase_characters   = data.aws_iam_account_password_policy.current.require_uppercase_characters
  require_numbers                = data.aws_iam_account_password_policy.current.require_numbers
  allow_users_to_change_password = data.aws_iam_account_password_policy.current.allow_users_to_change_password
  max_password_age              = data.aws_iam_account_password_policy.current.max_password_age
  password_reuse_prevention     = data.aws_iam_account_password_policy.current.password_reuse_prevention
}


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Uses the `aws_iam_account_password_policy` data source to get the current IAM password policy.
3. Creates a new `aws_iam_account_password_policy` resource with the required `require_symbols` setting set to `true`.
4. Inherits the other settings from the current password policy, such as minimum password length, character requirements, and password reuse prevention.

This will update the IAM password policy to require at least one non-alphanumeric character, while preserving the other existing password policy settings.