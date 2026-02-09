# Define a CloudWatch log group retention policy of at least 365 days
resource "aws_cloudwatch_log_group" "remediation_eks_log_group" {
  name              = "/aws/eks/0201_test/cluster"
  retention_in_days = 365
}

# Ensure the log group is associated with the correct EKS cluster
data "aws_eks_cluster" "remediation_eks_cluster" {
  name = "0201_test"
}

resource "aws_cloudwatch_log_stream" "remediation_eks_log_stream" {
  name           = "cluster"
  log_group_name = aws_cloudwatch_log_group.remediation_eks_log_group.name
  depends_on     = [aws_cloudwatch_log_group.remediation_eks_log_group]
}