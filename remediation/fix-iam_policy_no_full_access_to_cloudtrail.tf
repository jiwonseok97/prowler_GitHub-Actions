# Update the existing IAM policy to allow only the required CloudTrail actions
resource "aws_iam_policy" "remediation_prowler_readonly" {
  name        = "GitHubActionsProwlerRole-ProwlerReadOnly"
  description = "Prowler read-only access policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "cloudtrail:DescribeTrails",
          "cloudtrail:GetTrailStatus",
          "cloudtrail:LookupEvents"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "s3:GetBucketLocation",
          "s3:GetBucketAcl",
          "s3:ListAllMyBuckets"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "iam:GetRole",
          "iam:GetRolePolicy"
        ],
        Resource = "*"
      }
    ]
  })
}