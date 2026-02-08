provider "aws" {
  region = "ap-northeast-2"
}

# Data source to reference the existing IAM policy
data "aws_iam_policy" "aws_learner_dynamodb_policy" {
  name = "aws_learner_dynamodb_policy"
}

# Resource block to create a new IAM policy with reduced permissions
resource "aws_iam_policy" "reduced_permissions_policy" {
  name        = "reduced_permissions_policy"
  description = "IAM policy with reduced permissions"

  policy = <<EOF