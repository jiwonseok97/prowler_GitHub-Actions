# Modify the existing IAM policy to remove the overly broad "cloudtrail:*" permission
resource "aws_iam_policy" "remediation_aws_learner_dynamodb_policy" {
  name        = "remediation_aws_learner_dynamodb_policy"
  description = "Remediated IAM policy to remove cloudtrail:* privilege"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "dynamodb:*"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "cloudtrail:DescribeTrails",
          "cloudtrail:GetTrailStatus",
          "cloudtrail:LookupEvents"
        ],
        Resource = "*"
      }
    ]
  })
}

# Attach the remediated IAM policy to the appropriate IAM user(s)