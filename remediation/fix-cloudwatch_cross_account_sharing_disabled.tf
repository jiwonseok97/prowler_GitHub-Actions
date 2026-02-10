# Create a new IAM role with a trust policy that allows the specified account to assume the role
resource "aws_iam_role" "remediation_cloudwatch_cross_account_role" {
  name = "remediation-cloudwatch-cross-account-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
      }
    ]
  })
}

# Attach the CloudWatchAgentServerPolicy managed policy to the new IAM role
resource "aws_iam_role_policy_attachment" "remediation_cloudwatch_agent_policy" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.remediation_cloudwatch_cross_account_role.name
}

# Create an IAM instance profile and associate the new IAM role with it
resource "aws_iam_instance_profile" "remediation_cloudwatch_cross_account_instance_profile" {
  name = "remediation-cloudwatch-cross-account-instance-profile"
  role = aws_iam_role.remediation_cloudwatch_cross_account_role.name
}

# Attach the new IAM instance profile to the existing EC2 instance
resource "aws_iam_role_policy_attachment" "remediation_cloudwatch_cross_account_instance_profile_attachment" {
  policy_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:instance-profile/remediation-cloudwatch-cross-account-instance-profile"
  role       = "arn:aws:iam:ap-northeast-2:132410971304:role"
}