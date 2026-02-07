# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Data source to reference the existing IAM policy
data "aws_iam_policy" "aws_learner_dynamodb_policy" {
  name = "aws_learner_dynamodb_policy"
}

# Create a new IAM policy document with the recommended changes
data "aws_iam_policy_document" "aws_learner_dynamodb_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["arn:aws:kms:ap-northeast-2:132410971304:key/*"]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["dynamodb.amazonaws.com"]
    }
  }
}

# Create the updated IAM policy with the new policy document
resource "aws_iam_policy" "aws_learner_dynamodb_policy" {
  name        = "aws_learner_dynamodb_policy"
  description = "Custom IAM policy for DynamoDB access with limited KMS permissions"
  policy      = data.aws_iam_policy_document.aws_learner_dynamodb_policy_document.json
}


The provided Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Retrieves the existing IAM policy using the `data` source `aws_iam_policy`.
3. Creates a new IAM policy document with the recommended changes:
   - Allows only the necessary KMS actions (`Encrypt`, `Decrypt`, `ReEncrypt*`, `GenerateDataKey*`, `DescribeKey`) scoped to the specific KMS key ARN.
   - Adds a condition to restrict the KMS access to only the `dynamodb.amazonaws.com` service.
4. Creates the updated IAM policy using the new policy document.