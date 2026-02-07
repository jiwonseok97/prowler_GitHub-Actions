# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Data source to reference the existing IAM policy
data "aws_iam_policy" "aws_learner_dynamodb_policy" {
  name = "aws_learner_dynamodb_policy"
}

# Create a new version of the IAM policy with reduced KMS permissions
resource "aws_iam_policy_version" "aws_learner_dynamodb_policy_version" {
  policy_arn = data.aws_iam_policy.aws_learner_dynamodb_policy.arn
  set_as_default = true
  document = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ],
      "Resource": [
        "arn:aws:kms:ap-northeast-2:132410971304:key/*"
      ]
    }
  ]
}
POLICY
}


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Retrieves the existing IAM policy named `aws_learner_dynamodb_policy` using the `data` source.
3. Creates a new version of the IAM policy with reduced KMS permissions, allowing only the necessary actions (`kms:Encrypt`, `kms:Decrypt`, `kms:ReEncrypt*`, `kms:GenerateDataKey*`, and `kms:DescribeKey`) scoped to the specific KMS key ARN.