# Remove the unattached IAM policy
resource "aws_iam_policy" "remediation_remove_unattached_policy" {
  name        = "remediation_remove_unattached_policy"
  description = "Remediation: Remove unattached IAM policy"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Deny"
        Action = "*"
        Resource = "*"
      }
    ]
  })
}

# Attach the remediation policy to the current IAM user