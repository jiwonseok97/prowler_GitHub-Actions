# Modify the existing IAM policy to remove the overly broad "cloudtrail:*" permission
resource "aws_iam_policy" "remediation_iam_policy" {
  name        = "GitHubActionsProwlerRole-ProwlerReadOnly"
  description = "Remediated IAM policy to remove cloudtrail:* privilege"
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
        Resource = "*"
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