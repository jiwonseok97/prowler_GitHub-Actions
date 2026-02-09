# Create a new IAM role with a narrowly scoped policy for CloudShell access
resource "aws_iam_role" "remediation_cloudshell_role" {
  name = "remediation-cloudshell-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "cloudshell.amazonaws.com"
        }
      }
    ]
  })
}

# Attach the policy with the required permissions for CloudShell
resource "aws_iam_role_policy" "remediation_cloudshell_policy" {
  name = "remediation-cloudshell-policy"
  role = aws_iam_role.remediation_cloudshell_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "cloudshell:*"
        ],
        Resource = "*"
      }
    ]
  })
}