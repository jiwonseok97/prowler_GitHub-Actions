# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Update the IAM password policy to meet the recommended requirements
resource "aws_iam_account_password_policy" "strict" {
  # Require passwords to be at least 16 characters long
  minimum_password_length        = 16
  # Require at least one uppercase letter, one lowercase letter, and one number
  require_lowercase_characters   = true
  require_uppercase_characters   = true
  require_numbers                = true
  # Prevent password reuse
  password_reuse_prevention      = 24
  # Expire passwords after 90 days
  max_password_age               = 90
}