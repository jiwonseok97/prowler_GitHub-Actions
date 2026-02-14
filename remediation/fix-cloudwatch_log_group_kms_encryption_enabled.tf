# Associate the CloudWatch log group with a customer-managed KMS key
resource "aws_cloudwatch_log_group" "remediation_eks_cluster_log_group" {
  name = "aws-eks-0201_test-cluster"
  kms_key_id = aws_kms_key.remediation_eks_cluster_log_key.arn
}

# Create a customer-managed KMS key for encrypting the CloudWatch log group
resource "aws_kms_key" "remediation_eks_cluster_log_key" {
  description             = "Customer-managed KMS key for EKS cluster logs"
  deletion_window_in_days = 30
  enable_key_rotation     = true
}

# Attach a KMS key policy to grant required permissions
resource "aws_kms_key_policy" "remediation_eks_cluster_log_key_policy" {
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action = "kms:*",
        Resource = "*"
      },
      {
        Effect = "Allow",
        Principal = {
          Service = "logs.ap-northeast-2.amazonaws.com"
        },
        Action = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
        ],
        Resource = "*"
      }
    ]
  })
  key_id = aws_kms_key.remediation_eks_cluster_log_key.key_id
}