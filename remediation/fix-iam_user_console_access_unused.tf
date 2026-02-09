provider "aws" {
  region = "ap-northeast-2"
}

# Disable console access for the IAM user
resource "aws_iam_user_login_profile" "prowler_user_login_profile" {
  user                    = "prowler"
  password_length         = 20
  password_reset_required = true
}

# Attach a policy to the IAM user to deny console access
data "aws_iam_policy_document" "prowler_user_deny_console_access" {
  statement {
    effect = "Deny"
    actions = [