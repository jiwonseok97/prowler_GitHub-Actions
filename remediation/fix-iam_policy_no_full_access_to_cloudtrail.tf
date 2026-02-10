# Modify the existing IAM policy to remove the "cloudtrail:*" permission
resource "aws_iam_policy" "remediation_iam_policy" {
  name        = "remediation-cloudtrail-readonly"
  description = "Remediated IAM policy to remove 'cloudtrail:*' permission"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "cloudtrail:DescribeTrails",
          "cloudtrail:GetTrailStatus",
          "cloudtrail:LookupEvents"
        ],
        # Scope CloudTrail actions to a specific trail to satisfy tfsec
        Resource = "arn:aws:cloudtrail:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:trail/security-cloudtrail"
      },
      {
        Effect = "Allow",
        Action = [
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Resource = [
          "arn:aws:s3:::my-cloudtrail-bucket",
          "arn:aws:s3:::my-cloudtrail-bucket/*"
        ]
      }
    ]
  })
}

# Attach the remediated IAM policy to the existing IAM role
resource "aws_iam_role_policy_attachment" "remediation_iam_role_policy_attachment" {
  policy_arn = aws_iam_policy.remediation_iam_policy.arn
  role       = "GitHubActionsProwlerRole"
}
