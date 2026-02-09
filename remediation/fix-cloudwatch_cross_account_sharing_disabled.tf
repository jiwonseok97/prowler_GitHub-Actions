# Create a new CloudWatch Log Group to store cross-account logs
resource "aws_cloudwatch_log_group" "remediation_cross_account_log_group" {
  name = "remediation-cross-account-log-group"
}

# Create a new IAM role for cross-account CloudWatch access
resource "aws_iam_role" "remediation_cross_account_role" {
  name = "remediation-cross-account-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
      }
    ]
  })
}

# Attach the CloudWatchLogsFullAccess policy to the new IAM role
resource "aws_iam_role_policy_attachment" "remediation_cross_account_role_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
  role       = aws_iam_role.remediation_cross_account_role.name
}

# Create a new CloudWatch Log Destination to allow cross-account sharing
resource "aws_cloudwatch_log_destination" "remediation_cross_account_log_destination" {
  name       = "remediation-cross-account-log-destination"
  role_arn   = aws_iam_role.remediation_cross_account_role.arn
  target_arn = aws_cloudwatch_log_group.remediation_cross_account_log_group.arn
}