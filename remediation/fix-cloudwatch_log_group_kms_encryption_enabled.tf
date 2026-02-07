# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create a new KMS key for encrypting the CloudWatch log group
resource "aws_kms_key" "cloudwatch_log_group_key" {
  description             = "KMS key for encrypting CloudWatch log group"
  deletion_window_in_days = 30
  enable_key_rotation     = true
}

# Create a new CloudWatch log group and associate it with the KMS key
resource "aws_cloudwatch_log_group" "example_log_group" {
  name              = "/aws/eks/0202_test/cluster"
  kms_key_id        = aws_kms_key.cloudwatch_log_group_key.arn
  retention_in_days = 90
}

# Add IAM policy to grant the required principals access to the KMS key
data "aws_iam_policy_document" "cloudwatch_log_group_key_policy" {
  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
    ]
    resources = [
      aws_kms_key.cloudwatch_log_group_key.arn,
    ]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::132410971304:root"]
    }
  }
}

resource "aws_kms_key_policy" "cloudwatch_log_group_key_policy" {
  key_id = aws_kms_key.cloudwatch_log_group_key.id
  policy = data.aws_iam_policy_document.cloudwatch_log_group_key_policy.json
}


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Creates a new KMS key for encrypting the CloudWatch log group, with a 30-day deletion window and key rotation enabled.
3. Creates a new CloudWatch log group and associates it with the KMS key created in the previous step.
4. Adds an IAM policy to the KMS key, granting the required principals (in this case, the root user) the `kms:Decrypt` permission.