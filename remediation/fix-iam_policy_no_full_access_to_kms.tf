# Modify the existing IAM policy to remove the 'kms:*' privilege and only allow the required KMS actions
resource "aws_iam_policy" "remediation_iam_policy" {
  name        = "GitHubActionsProwlerRole-ProwlerReadOnly"
  description = "Custom IAM policy with least privilege KMS access"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        Resource = [
          "arn:aws:kms:ap-northeast-2:${data.aws_caller_identity.current.account_id}:key/*"
        ]
      },
      # Add other required permissions here
    ]
  })
}

# Attach the modified IAM policy to the existing GitHubActionsProwlerRole-ProwlerReadOnly role
resource "aws_iam_role_policy_attachment" "remediation_iam_role_policy_attachment" {
  policy_arn = aws_iam_policy.remediation_iam_policy.arn
  role       = "GitHubActionsProwlerRole-ProwlerReadOnly"
}