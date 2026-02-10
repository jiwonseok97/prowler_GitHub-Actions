# Disable console access for the IAM user
resource "aws_iam_user_login_profile" "remediation_aws_learner_console_access" {
  user                    = "aws_learner"
  password_length         = 20
  password_reset_required = true
  pgp_key                 = "keybase:some_person_that_exists"
}

# Attach a policy to the IAM user to restrict console access
resource "aws_iam_user_policy_attachment" "remediation_aws_learner_no_console_access" {
  user       = "aws_learner"
  policy_arn = "arn:aws:iam::aws:policy/IAMUserChangePassword"
}