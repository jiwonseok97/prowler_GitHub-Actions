# Create a customer-managed KMS key for encrypting the CloudWatch log group
resource "aws_kms_key" "remediation_cloudwatch_log_group_key" {
  description             = "Customer-managed KMS key for CloudWatch log group encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true
}

# Associate the KMS key with the CloudWatch log group
resource "aws_cloudwatch_log_group" "remediation_cloudwatch_log_group" {
  name = "aws-eks-0201_test-cluster"
  kms_key_id        = aws_kms_key.remediation_cloudwatch_log_group_key.id
  retention_in_days = 90
}

# Grant the required IAM permissions to access the KMS key
data "aws_iam_policy_document" "remediation_cloudwatch_log_group_kms_key_policy" {
  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
    ]
    resources = [
      aws_kms_key.remediation_cloudwatch_log_group_key.arn,
    ]
    principals {
      type        = "Service"
      identifiers = ["logs.ap-northeast-2.amazonaws.com"]
    }
  }
}

resource "aws_kms_key_policy" "remediation_cloudwatch_log_group_kms_key_policy" {
  policy   = data.aws_iam_policy_document.remediation_cloudwatch_log_group_kms_key_policy.json
  depends_on = [
    aws_cloudwatch_log_group.remediation_cloudwatch_log_group,
  ]
  key_id = aws_kms_key.remediation_cloudwatch_log_group_key.key_id
}