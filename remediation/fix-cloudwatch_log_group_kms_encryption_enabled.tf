# Create a new KMS key for encrypting the CloudWatch log group
resource "aws_kms_key" "remediation_cloudwatch_log_group_kms_key" {
  description             = "Remediation KMS key for CloudWatch log group encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true
}

# Create a new IAM policy to grant the required permissions for the KMS key
resource "aws_iam_policy" "remediation_cloudwatch_log_group_kms_key_policy" {
  name        = "remediation-cloudwatch-log-group-kms-key-policy"
  description = "Grants kms:Decrypt permission for the CloudWatch log group KMS key"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = "kms:Decrypt",
        Resource = aws_kms_key.remediation_cloudwatch_log_group_kms_key.arn
      }
    ]
  })
}

# Create a new CloudWatch log group with the new KMS key
resource "aws_cloudwatch_log_group" "remediation_cloudwatch_log_group" {
  name              = "/aws/eks/0201_test/cluster"
  kms_key_id        = aws_kms_key.remediation_cloudwatch_log_group_kms_key.key_id
  retention_in_days = 30
}