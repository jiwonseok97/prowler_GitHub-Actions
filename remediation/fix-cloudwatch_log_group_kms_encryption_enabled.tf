# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create a new KMS key for encrypting the CloudWatch log group
resource "aws_kms_key" "cloudwatch_log_group_key" {
  description             = "KMS key for encrypting CloudWatch log group /aws/eks/0202_test/cluster"
  deletion_window_in_days = 30
  enable_key_rotation     = true
}

# Create a new CloudWatch log group and associate it with the KMS key
resource "aws_cloudwatch_log_group" "eks_cluster_log_group" {
  name              = "/aws/eks/0202_test/cluster"
  kms_key_id        = aws_kms_key.cloudwatch_log_group_key.arn
  retention_in_days = 90
}

# Grant the required IAM permissions to the KMS key
resource "aws_kms_key_policy" "cloudwatch_log_group_key_policy" {
  key_id = aws_kms_key.cloudwatch_log_group_key.id
  policy = data.aws_iam_policy_document.cloudwatch_log_group_key_policy.json
}

data "aws_iam_policy_document" "cloudwatch_log_group_key_policy" {
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
      type        = "Service"
      identifiers = ["logs.ap-northeast-2.amazonaws.com"]
    }
  }
}


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Creates a new KMS key for encrypting the CloudWatch log group `/aws/eks/0202_test/cluster`.
3. Enables key rotation and sets a 30-day deletion window for the KMS key.
4. Creates a new CloudWatch log group and associates it with the KMS key.
5. Grants the required IAM permissions to the KMS key, allowing the `logs.ap-northeast-2.amazonaws.com` service to use the key for encryption and decryption.