# Create a new IAM policy with the required permissions for CloudTrail
resource "aws_iam_policy" "remediation_cloudtrail_policy" {
  name        = "remediation-cloudtrail-policy"
  description = "Allows required CloudTrail actions"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "cloudtrail:DescribeTrails",
          "cloudtrail:GetTrailStatus",
          "cloudtrail:LookupEvents",
          "cloudtrail:StartLogging",
          "cloudtrail:StopLogging"
        ],
        Resource = "*"
      }
    ]
  })
}

# Create a new IAM role with the remediation policy attached
resource "aws_iam_role" "remediation_cloudtrail_role" {
  name               = "remediation-cloudtrail-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          AWS = "*"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "remediation_cloudtrail_policy_attachment" {
  policy_arn = aws_iam_policy.remediation_cloudtrail_policy.arn
  role       = aws_iam_role.remediation_cloudtrail_role.name
}