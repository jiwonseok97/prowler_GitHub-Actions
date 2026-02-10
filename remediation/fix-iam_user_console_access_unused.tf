# Disable console access for the IAM user
resource "aws_iam_user_login_profile" "remediation_aws_learner_console_access" {
  user                    = "aws_learner"
  password_reset_required = true
  password_length         = 20
}

# Attach a policy to the IAM user to deny console access
resource "aws_iam_user_policy" "remediation_aws_learner_console_access_deny" {
  name = "deny-console-access"
  user = "aws_learner"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Deny",
        Action = "iam:GetLoginProfile",
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/aws_learner"
      }
    ]
  })
}