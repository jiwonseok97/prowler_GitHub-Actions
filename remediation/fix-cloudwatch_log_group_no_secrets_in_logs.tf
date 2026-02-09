# Create a new CloudWatch log group with a shorter retention period
resource "aws_cloudwatch_log_group" "remediation_log_group" {
  name              = "/aws/eks/0201_test/cluster"
  retention_in_days = 30
}

# Create a new IAM policy to audit and mask sensitive patterns in the log group
resource "aws_iam_policy" "remediation_log_protection_policy" {
  name        = "remediation-log-protection-policy"
  description = "Audit and mask sensitive patterns in the CloudWatch log group"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:Describe*",
          "logs:Get*",
          "logs:List*",
          "logs:StartQuery",
          "logs:StopQuery",
          "logs:TestMetricFilter",
          "logs:FilterLogEvents"
        ],
        Resource = aws_cloudwatch_log_group.remediation_log_group.arn
      },
      {
        Effect = "Allow",
        Action = [
          "logs:Unmask"
        ],
        Resource = aws_cloudwatch_log_group.remediation_log_group.arn,
        Condition = {
          StringEquals = {
            "logs:RequestedLogFormat" = "json"
          }
        }
      }
    ]
  })
}

# Create a new IAM role to restrict access to the log group
resource "aws_iam_role" "remediation_log_reader_role" {
  name = "remediation-log-reader-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach the log protection policy to the new IAM role
resource "aws_iam_role_policy_attachment" "remediation_log_protection_policy_attachment" {
  policy_arn = aws_iam_policy.remediation_log_protection_policy.arn
  role       = aws_iam_role.remediation_log_reader_role.name
}