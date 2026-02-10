# Remove the unattached customer-managed IAM policy that grants administrative privileges
resource "aws_iam_policy" "remediation_cloudtrail_readonly" {
  name        = "remediation-cloudtrail-readonly"
  description = "Remediation: Unattached customer-managed IAM policy that does not allow '*:*' administrative privileges"
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

# Attach the remediated IAM policy to the appropriate IAM users or roles
resource "aws_iam_user_policy_attachment" "remediation_cloudtrail_readonly_attachment" {
  user       = "example-user"
  policy_arn = aws_iam_policy.remediation_cloudtrail_readonly.arn
}

resource "aws_iam_role_policy_attachment" "remediation_cloudtrail_readonly_attachment" {
  role       = "example-role"
  policy_arn = aws_iam_policy.remediation_cloudtrail_readonly.arn
}