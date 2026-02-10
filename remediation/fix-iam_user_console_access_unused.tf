# Disable console access for the IAM user
resource "aws_iam_user_login_profile" "remediation_aws_learner" {
  user    = "aws_learner"
  pgp_key = "keybase:some_person_that_exists"
  
  # Disable console access
  password_reset_required = true
  password_length        = 20
}

# Attach a policy to the IAM user to enforce MFA for console access