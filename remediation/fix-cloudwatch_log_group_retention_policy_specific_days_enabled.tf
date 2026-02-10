# Modify the CloudWatch log group retention policy
resource "aws_cloudwatch_log_group" "remediation_eks_log_group" {
  name              = "/aws/eks/0201_test/cluster"
  retention_in_days = 365
}