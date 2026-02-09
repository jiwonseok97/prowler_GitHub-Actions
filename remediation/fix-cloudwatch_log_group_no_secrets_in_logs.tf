provider "aws" {
  region = "ap-northeast-2"
}

# Data source to reference the existing CloudWatch log group
data "aws_cloudwatch_log_group" "eks_cluster_log_group" {
  name = "/aws/eks/0202_test/cluster"
}

# Resource to configure the CloudWatch log group retention policy
resource "aws_cloudwatch_log_group_retention_policy" "eks_cluster_log_group_retention" {
  log_group_name = data.aws_cloudwatch_log_group.eks_cluster_log_group.name
  retention_in_days = 90
}

# Resource to configure the CloudWatch log group data protection policy
resource "aws_cloudwatch_log_group_data_protection_policy" "eks_cluster_log_group_data_protection" {
  log_group_name = data.aws_cloudwatch_log_group.eks_cluster_log_group.name
  policy_document = <<POLICY