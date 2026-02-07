# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Use the aws_iam_account_password_policy data source to reference the existing password policy
data "aws_iam_account_password_policy" "current" {}

# Update the password policy to require at least one number
resource "aws_iam_account_password_policy" "updated" {
  minimum_password_length        = data.aws_iam_account_password_policy.current.minimum_password_length
  require_lowercase_characters   = data.aws_iam_account_password_policy.current.require_lowercase_characters
  require_uppercase_characters   = data.aws_iam_account_password_policy.current.require_uppercase_characters
  require_symbols                = data.aws_iam_account_password_policy.current.require_symbols
  require_numbers                = true # Enforce the requirement for at least one number
  allow_users_to_change_password = data.aws_iam_account_password_policy.current.allow_users_to_change_password
  max_password_age               = data.aws_iam_account_password_policy.current.max_password_age
  password_reuse_prevention      = data.aws_iam_account_password_policy.current.password_reuse_prevention
  hard_expiry                    = data.aws_iam_account_password_policy.current.hard_expiry
}