# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Update the IAM password policy to meet the security finding
resource "aws_iam_account_password_policy" "strict" {
  minimum_password_length        = 16
  require_lowercase_characters   = true
  require_uppercase_characters   = true
  require_numbers                = true
  require_symbols                = true
  allow_users_to_change_password = true
  max_password_age               = 90
  password_reuse_prevention      = 24
}


The provided Terraform code updates the IAM password policy to meet the security finding. Specifically, it:

1. Sets the minimum password length to 16 characters.
2. Requires the use of lowercase, uppercase, numeric, and special characters.
3. Allows users to change their passwords.
4. Sets the maximum password age to 90 days.
5. Prevents the reuse of the last 24 passwords.

This should address the security finding and improve the overall password security for the IAM users in the ap-northeast-2 region.