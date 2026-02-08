provider "aws" {
  region = "ap-northeast-2"
}

# Fetch the existing CloudWatch log group
data "aws_cloudwatch_log_group" "eks_cluster_log_group" {
  name = "/aws/eks/0202_test/cluster"
}

# Set the retention policy for the log group to 365 days
resource "aws_cloudwatch_log_group" "eks_cluster_log_group" {
  name              = data.aws_cloudwatch_log_group.eks_cluster_log_group.name
  retention_in_days = 365
}