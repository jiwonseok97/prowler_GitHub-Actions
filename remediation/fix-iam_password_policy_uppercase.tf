provider "aws" {
  region = "ap-northeast-2"
}

# Create an IAM password policy with the required uppercase rule
resource "aws_iam_account_password_policy" "strong_password_policy" {
  minimum_password_length        = 14
  require_lowercase_characters   = true
  require_numbers                = true
  require_symbols                = true
  require_uppercase_characters   = true
  allow_users_to_change_password = true
}

# Optionally, import the existing password policy resource
# This is necessary if the policy already exists and you want to manage it with Terraform
# resource "aws_iam_account_password_policy" "existing_password_policy" {
#   provider = aws
# }
# 
# data "aws_iam_account_password_policy" "existing" {}
# 
# import "aws_iam_account_password_policy" "existing_password_policy" "${data.aws_iam_account_password_policy.existing.id}"