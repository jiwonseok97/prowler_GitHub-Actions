# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create an IAM password policy to prevent reuse of the last 24 passwords
resource "aws_iam_account_password_policy" "strict" {
  minimum_password_length        = 14
  require_lowercase_characters   = true
  require_numbers                = true
  require_uppercase_characters   = true
  require_symbols                = true
  allow_users_to_change_password = true
  password_reuse_prevention      = 24
  max_password_age              = 90
}


This Terraform code creates an IAM password policy that enforces the following requirements:

1. Minimum password length of 14 characters
2. Requires at least one lowercase character
3. Requires at least one number
4. Requires at least one uppercase character
5. Requires at least one symbol
6. Allows users to change their own passwords
7. Prevents the reuse of the last 24 passwords
8. Sets a maximum password age of 90 days

This policy helps to address the security finding by ensuring that users cannot reuse their previous 24 passwords, which improves password security and reduces the risk of unauthorized access.