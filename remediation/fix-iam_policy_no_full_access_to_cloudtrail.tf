# Create a new IAM policy with the required permissions
resource "aws_iam_policy" "remediation_cloudtrail_readonly" {
  name        = "remediation-cloudtrail-readonly"
  description = "Allows read-only access to CloudTrail"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "cloudtrail:DescribeTrails",
          "cloudtrail:GetTrailStatus",
          "cloudtrail:LookupEvents",
          "cloudtrail:ListTags"
        ],
        Resource = "*"
      }
    ]
  })
}

# Attach the new IAM policy to the existing IAM user
resource "aws_iam_user_policy_attachment" "remediation_cloudtrail_readonly_attachment" {
  user       = "your-iam-user-name"
  policy_arn = aws_iam_policy.remediation_cloudtrail_readonly.arn
}