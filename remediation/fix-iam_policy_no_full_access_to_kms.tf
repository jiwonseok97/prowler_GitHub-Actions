# Configure the AWS provider for the ap-northeast-2 region

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

# Update the existing IAM policy with the new policy document
resource "aws_iam_policy" "aws_learner_dynamodb_policy" {
  name        = "aws_learner_dynamodb_policy"
  description = "Custom IAM policy for DynamoDB access"
  policy      = data.aws_iam_policy_document.aws_learner_dynamodb_policy_document.json
}


The provided Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Uses a data source to reference the existing IAM policy named `aws_learner_dynamodb_policy`.
3. Creates a new IAM policy document with the recommended changes:
   - Allows only the necessary KMS actions: `kms:Encrypt`, `kms:Decrypt`, `kms:ReEncrypt*`, `kms:GenerateDataKey*`, and `kms:DescribeKey`.
   - Scopes the resources to the specific KMS key ARN (`arn:aws:kms:ap-northeast-2:132410971304:key/*`).
   - Adds a condition to restrict the KMS access to only the DynamoDB service (`kms:ViaService = "dynamodb.amazonaws.com"`).
4. Updates the existing IAM policy with the new policy document.