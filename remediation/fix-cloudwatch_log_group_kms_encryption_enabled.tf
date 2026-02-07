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

# Define the IAM policy document for the KMS key
data "aws_iam_policy_document" "cloudwatch_log_group_key_policy" {
  statement {
    effect = "Allow"
    actions = ["kms:Decrypt"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::132410971304:root"]
    }
  }
}


The provided Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Creates a new KMS key for encrypting the CloudWatch log group `/aws/eks/0202_test/cluster`.
3. Enables key rotation and sets a 30-day deletion window for the KMS key.
4. Creates a new CloudWatch log group `/aws/eks/0202_test/cluster` and associates it with the newly created KMS key.
5. Defines an IAM policy document that grants the `kms:Decrypt` permission to the root user (arn:aws:iam::132410971304:root) for the KMS key.
6. Attaches the IAM policy document to the KMS key using the `aws_kms_key_policy` resource.

This Terraform code should address the security finding by creating a customer-managed KMS key and associating it with the CloudWatch log group, as recommended in the finding.