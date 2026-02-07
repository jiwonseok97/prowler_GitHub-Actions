# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Data source to reference the existing IAM policy
data "aws_iam_policy" "aws_learner_dynamodb_policy" {
  name = "aws_learner_dynamodb_policy"
}

# Create a new IAM policy version with reduced permissions
resource "aws_iam_policy_version" "aws_learner_dynamodb_policy_version" {
  policy_arn = data.aws_iam_policy.aws_learner_dynamodb_policy.arn
  version_id = "v2"
  document   = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "dynamodb:DescribeTable",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem"
        ],
        "Resource": "arn:aws:dynamodb:ap-northeast-2:132410971304:table/my-dynamodb-table"
      }
    ]
  }
  EOF
}

# Set the new policy version as the default version
resource "aws_iam_policy" "aws_learner_dynamodb_policy" {
  name   = "aws_learner_dynamodb_policy"
  policy = data.aws_iam_policy.aws_learner_dynamodb_policy.policy
  default_version_id = aws_iam_policy_version.aws_learner_dynamodb_policy_version.version_id
}


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Retrieves the existing IAM policy using the `data` source.
3. Creates a new IAM policy version with reduced permissions, scoping the actions and resources to a specific DynamoDB table.
4. Sets the new policy version as the default version of the IAM policy.

This addresses the security finding by removing the `*:*` administrative privileges and enforcing the principle of least privilege.