# Associate the CloudWatch log group with a customer-managed KMS key
resource "aws_cloudwatch_log_group" "remediation_eks_cluster_log_group" {
  name              = "aws-eks-0201_test-cluster"
  kms_key_id        = aws_kms_key.remediation_eks_cluster_log_key.arn
  retention_in_days = 90
}

# Create a customer-managed KMS key for encrypting the CloudWatch log group
resource "aws_kms_key" "remediation_eks_cluster_log_key" {
  description             = "Customer-managed KMS key for EKS cluster logs"
  deletion_window_in_days = 30
  enable_key_rotation     = true
}

# Grant the required IAM permissions to the KMS key policy
data "aws_iam_policy_document" "remediation_eks_cluster_log_key_policy" {
  statement {
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}

resource "aws_kms_key_policy" "remediation_eks_cluster_log_key_policy" {
  policy     = data.aws_iam_policy_document.remediation_eks_cluster_log_key_policy.json
  depends_on = [aws_kms_key.remediation_eks_cluster_log_key]
  key_id     = aws_kms_key.remediation_eks_cluster_log_key.key_id
}
