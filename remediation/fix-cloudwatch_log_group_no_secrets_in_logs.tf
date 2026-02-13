# Modify the CloudWatch log group to enable log data protection
resource "aws_cloudwatch_log_group" "remediation_eks_cluster_log_group" {
  name = "aws-eks-0201_test-cluster"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.remediation_eks_cluster_log_group_key.arn
}

# Create a KMS key to encrypt the CloudWatch log group
resource "aws_kms_key" "remediation_eks_cluster_log_group_key" {
  description             = "KMS key for EKS cluster log group"
  deletion_window_in_days = 10
}

# Attach a CloudWatch Logs data protection policy to the log group
resource "aws_cloudwatch_log_resource_policy" "remediation_eks_cluster_log_group_policy" {
  policy_name = "remediation-eks-cluster-log-group-policy"
  policy_document = jsonencode({
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "logs.amazonaws.com"
        },
        Action = [
          "logs:PutResourcePolicy",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:FilterLogEvents"
        ],
        Resource = aws_cloudwatch_log_group.remediation_eks_cluster_log_group_1.arn
      },
      {
        Effect = "Allow",
        Principal = {
          AWS = "*"
        },
        Action = [
          "logs:Describe*",
          "logs:Get*",
          "logs:TestMetricFilter",
          "logs:FilterLogEvents"
        ],
        Resource = aws_cloudwatch_log_group.remediation_eks_cluster_log_group_1.arn,
        Condition = {
          StringEquals = {
            "aws:PrincipalOrgID" = "o-1234567"
          }
        }
      }
    ]
  })
}

# Reduce the CloudWatch log group retention period to 30 days
resource "aws_cloudwatch_log_group" "remediation_eks_cluster_log_group_1" {
  name = "aws-eks-0201_test-cluster"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.remediation_eks_cluster_log_group_key.arn
}