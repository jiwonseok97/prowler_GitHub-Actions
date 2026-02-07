# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Retrieve the existing IAM password policy
data "aws_iam_account_password_policy" "current" {}

# Update the IAM password policy to require at least one symbol
resource "aws_iam_account_password_policy" "updated" {
  minimum_password_length        = data.aws_iam_account_password_policy.current.minimum_password_length
  require_lowercase_characters   = data.aws_iam_account_password_policy.current.require_lowercase_characters
  require_numbers                = data.aws_iam_account_password_policy.current.require_numbers
  require_uppercase_characters   = data.aws_iam_account_password_policy.current.require_uppercase_characters
  require_symbols                = true # Require at least one symbol
  allow_users_to_change_password = data.aws_iam_account_password_policy.current.allow_users_to_change_password
  max_password_age               = data.aws_iam_account_password_policy.current.max_password_age
  password_reuse_prevention      = data.aws_iam_account_password_policy.current.password_reuse_prevention
}


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Retrieves the existing IAM password policy using the `aws_iam_account_password_policy` data source.
3. Updates the IAM password policy by setting the `require_symbols` attribute to `true`, which enforces the requirement of at least one non-alphanumeric character in the password.
4. The rest of the password policy settings are preserved from the existing policy.