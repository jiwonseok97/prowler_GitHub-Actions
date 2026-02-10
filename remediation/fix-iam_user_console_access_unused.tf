# Disable console access for the IAM user
resource "aws_iam_user_login_profile" "remediation_aws_learner" {
  user    = "aws_learner"
  pgp_key = "keybase:some_person_that_exists"
  
  # Disable console access by setting password_reset_required to true
  password_reset_required = true
}

# Attach a policy to the IAM user to enforce MFA for console access
resource "aws_iam_user_policy_attachment" "remediation_aws_learner_mfa_policy" {
  user       = "aws_learner"
  policy_arn = "arn:aws:iam::aws:policy/IAMUserChangePassword"
}