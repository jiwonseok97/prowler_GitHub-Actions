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

# Update the IAM policy to remove the 'kms:*' privilege and add specific KMS actions
resource "aws_iam_policy" "aws_learner_dynamodb_policy_updated" {
  name   = "aws_learner_dynamodb_policy_updated"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [