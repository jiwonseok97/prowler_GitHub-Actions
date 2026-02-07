# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Use the existing IAM password policy resource
data "aws:iam_account_password_policy" "existing" {
  # No changes needed
}

# Update the IAM password policy to require at least one symbol
resource "aws_iam_account_password_policy" "updated" {
  minimum_password_length        = data.aws:iam_account_password_policy.existing.minimum_password_length
  require_lowercase_characters   = data.aws:iam_account_password_policy.existing.require_lowercase_characters
  require_numbers                = data.aws:iam_account_password_policy.existing.require_numbers
  require_uppercase_characters   = data.aws:iam_account_password_policy.existing.require_uppercase_characters
  require_symbols                = true # Require at least one symbol
  allow_users_to_change_password = data.aws:iam_account_password_policy.existing.allow_users_to_change_password
  max_password_age               = data.aws:iam_account_password_policy.existing.max_password_age
  password_reuse_prevention      = data.aws:iam_account_password_policy.existing.password_reuse_prevention
}