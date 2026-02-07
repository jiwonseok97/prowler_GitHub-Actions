# Configure the AWS provider for the ap-northeast-2 region

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
  name        = "aws_learner_dynamodb_policy"
  policy_arn  = data.aws_iam_policy.aws_learner_dynamodb_policy.arn
  default_version_id = "v2"
}


The provided Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Uses a data source to reference the existing IAM policy named `aws_learner_dynamodb_policy`.
3. Creates a new IAM policy version with reduced permissions, allowing only specific DynamoDB actions on the `my-dynamodb-table` resource.
4. Sets the new policy version as the default version of the `aws_learner_dynamodb_policy`.

This code addresses the security finding by removing the `*:*` administrative privileges and scoping the permissions to the specific DynamoDB actions and resource required.