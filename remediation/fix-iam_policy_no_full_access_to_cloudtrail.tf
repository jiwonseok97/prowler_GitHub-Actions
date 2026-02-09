provider "aws" {
  region = "ap-northeast-2"
}

# Data source to reference the existing IAM policy
data "aws_iam_policy" "aws_learner_dynamodb_policy" {
  name = "aws_learner_dynamodb_policy"
}

# Import the existing IAM policy into Terraform management
resource "aws_iam_policy" "aws_learner_dynamodb_policy" {
  name   = "aws_learner_dynamodb_policy"
  policy = data.aws_iam_policy.aws_learner_dynamodb_policy.policy
}

# Create a new IAM policy with the recommended permissions
resource "aws_iam_policy" "cloudtrail_readonly_policy" {
  name = "cloudtrail-readonly-policy"

  policy = <<EOF