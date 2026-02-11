# Modify the existing IAM policy to remove the kms:* privilege
resource "aws_iam_policy" "remediation_iam_policy" {
  name        = "GitHubActionsProwlerRole-ProwlerReadOnly"
  description = "Custom IAM policy does not allow 'kms:*' privileges"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "kms:Describe*",
          "kms:Get*",
          "kms:List*",
          "kms:RevokeGrant",
          "kms:ScheduleKeyDeletion"
        ],
        Resource = [
          "arn:aws:kms:ap-northeast-2:${data.aws_caller_identity.current.account_id}:key/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Resource = [
          "arn:aws:s3:::my-bucket",
          "arn:aws:s3:::my-bucket/*"
        ]
      }
    ]
  })
}

# Attach the modified IAM policy to the existing GitHubActionsProwlerRole