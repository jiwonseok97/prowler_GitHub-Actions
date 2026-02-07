# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Data source to reference the existing IAM policy
data "aws_iam_policy" "aws_learner_dynamodb_policy" {
  name = "aws_learner_dynamodb_policy"
}

# Create a new IAM policy document with the required permissions
data "aws_iam_policy_document" "aws_learner_dynamodb_policy_document" {
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
resource "aws_iam_policy" "aws_learner_dynamodb_policy" {
  name        = "aws_learner_dynamodb_policy"
  description = "Updated IAM policy with least privilege CloudTrail permissions"
  policy      = data.aws_iam_policy_document.aws_learner_dynamodb_policy_document.json
}