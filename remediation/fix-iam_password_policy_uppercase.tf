# Configure the AWS provider for the ap-northeast-2 region

# Use the aws_iam_account_password_policy data source to get the current password policy
data "aws_iam_account_password_policy" "current" {}

# Create a new password policy with the uppercase requirement
resource "aws_iam_account_password_policy" "strong" {
  minimum_password_length        = data.aws_iam_account_password_policy.current.minimum_password_length
  require_lowercase_characters   = data.aws_iam_account_password_policy.current.require_lowercase_characters
  require_numbers                = data.aws_iam_account_password_policy.current.require_numbers
  require_symbols                = data.aws_iam_account_password_policy.current.require_symbols
  require_uppercase_characters   = true # Enable the uppercase requirement
  allow_users_to_change_password = data.aws_iam_account_password_policy.current.allow_users_to_change_password
}


# This Terraform code does the following:
# 
# 1. Configures the AWS provider for the `ap-northeast-2` region.
# 2. Uses the `aws_iam_account_password_policy` data source to get the current password policy.
# 3. Creates a new `aws_iam_account_password_policy` resource with the same settings as the current policy, but with the `require_uppercase_characters` parameter set to `true` to enable the uppercase requirement.