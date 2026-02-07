# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Data source to reference the existing IAM policy
data "aws_iam_policy" "aws_learner_dynamodb_policy" {
  name = "aws_learner_dynamodb_policy"
}

# Create a new IAM policy document with the required permissions
data "aws_iam_policy_document" "cloudtrail_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "cloudtrail:GetTrailStatus",
      "cloudtrail:DescribeTrails",
      "cloudtrail:LookupEvents"
    ]
    resources = ["*"]
  }
}

# Create a new IAM policy with the updated permissions
resource "aws_iam_policy" "cloudtrail_policy" {
  name        = "cloudtrail_policy"
  description = "Allows access to specific CloudTrail actions"
  policy      = data.aws_iam_policy_document.cloudtrail_policy_document.json
}

# Attach the new IAM policy to the existing IAM policy
resource "aws_iam_policy_attachment" "cloudtrail_policy_attachment" {
  name       = "cloudtrail-policy-attachment"
  policy_arn = aws_iam_policy.cloudtrail_policy.arn
  roles      = [data.aws_iam_policy.aws_learner_dynamodb_policy.roles[0]]
}


This Terraform code does the following:

1. Configures the AWS provider for the ap-northeast-2 region.
2. Retrieves the existing IAM policy using the `data` source.
3. Creates a new IAM policy document with the required CloudTrail permissions.
4. Creates a new IAM policy with the updated permissions.
5. Attaches the new IAM policy to the existing IAM policy.

The new IAM policy allows the following actions:
- `cloudtrail:GetTrailStatus`
- `cloudtrail:DescribeTrails`
- `cloudtrail:LookupEvents`

This ensures that the IAM policy follows the principle of least privilege and does not grant full access to CloudTrail.