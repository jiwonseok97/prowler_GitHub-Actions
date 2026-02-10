# Deny console access for unused IAM user
resource "aws_iam_user_policy" "remediation_aws_learner_deny_console" {
  name   = "remediation-deny-console-access"
  user   = "aws_learner"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DenyConsoleAccess"
        Effect   = "Deny"
        Action   = [
          "iam:ChangePassword",
          "iam:CreateLoginProfile",
          "iam:UpdateLoginProfile"
        ]
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/aws_learner"
      }
    ]
  })
}
