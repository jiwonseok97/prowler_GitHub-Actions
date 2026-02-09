provider "aws" {
  region = "ap-northeast-2"
}

# Create a new KMS key for encrypting the CloudWatch log group
resource "aws_kms_key" "cloudwatch_log_group_key" {
  description             = "KMS key for encrypting CloudWatch log group"
  deletion_window_in_days = 30
  enable_key_rotation     = true
}

# Create a CloudWatch log group and associate it with the new KMS key
resource "aws_cloudwatch_log_group" "example" {
  name              = "/aws/eks/0202_test/cluster"
  kms_key_id        = aws_kms_key.cloudwatch_log_group_key.key_id
  retention_in_days = 90
}

# Add IAM policy to grant required permissions for the KMS key
data "aws_iam_policy_document" "cloudwatch_log_group_key_policy" {
  statement {
    effect = "Allow"
    actions = [