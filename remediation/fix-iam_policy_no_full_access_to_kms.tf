# Modify the existing IAM policy to remove the kms:* privilege
resource "aws_iam_policy" "remediation_cloudtrail_readonly" {
  name        = "remediation-cloudtrail-readonly"
  description = "Remediated IAM policy to remove kms:* privilege"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "cloudtrail:DescribeTrails",
          "cloudtrail:GetTrailStatus",
          "cloudtrail:LookupEvents",
          "cloudtrail:ListTags",
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:GetKeyPolicy",
          "kms:GetKeyRotationStatus",
          "kms:ListAliases",
          "kms:ListKeys"
        ],
        Resource = "*"
      }
    ]
  })
}

# Attach the remediated IAM policy to the existing user
resource "aws_iam_user_policy_attachment" "remediation_cloudtrail_readonly" {
  user       = "your-iam-user-name"
  policy_arn = aws_iam_policy.remediation_cloudtrail_readonly.arn
}