# Create a new CloudWatch log group with a more restrictive retention policy
resource "aws_cloudwatch_log_group" "remediation_eks_cluster_logs" {
  name              = "/aws/eks/0201_test/cluster"
  retention_in_days = 30
}

# Create an IAM policy to mask sensitive data in CloudWatch logs
data "aws_iam_policy_document" "remediation_cloudwatch_logs_masking_policy" {
  statement {
    effect = "Allow"
    actions = [
      "logs:Describe*",
      "logs:Get*",
      "logs:List*",
      "logs:StartQuery",
      "logs:StopQuery",
      "logs:Tail",
      "logs:TestMetricFilter",
      "logs:FilterLogEvents",
    ]
    resources = [
      aws_cloudwatch_log_group.remediation_eks_cluster_logs.arn,
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:Unmask",
    ]
    resources = [
      aws_cloudwatch_log_group.remediation_eks_cluster_logs.arn,
    ]
    condition {
      test     = "StringEquals"
      variable = "logs:RequestedLogFormat"
      values   = ["json"]
    }
  }
}

resource "aws_iam_policy" "remediation_cloudwatch_logs_masking_policy" {
  name        = "remediation-cloudwatch-logs-masking-policy"
  description = "Allows masking of sensitive data in CloudWatch logs"
  policy      = jsonencode(data.aws_iam_policy_document.remediation_cloudwatch_logs_masking_policy.json)
}

# Attach the masking policy to the IAM role used by the EKS cluster
data "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"
}

resource "aws_iam_role_policy_attachment" "remediation_eks_cluster_role_cloudwatch_logs_masking_policy" {
  policy_arn = aws_iam_policy.remediation_cloudwatch_logs_masking_policy.arn
  role       = data.aws_iam_role.eks_cluster_role.name
}