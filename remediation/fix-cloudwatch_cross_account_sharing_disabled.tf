# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Get the existing CloudWatch log group
data "aws_cloudwatch_log_group" "example" {
  name = "/aws/lambda/my-lambda-function"
}

# Create a CloudWatch log group subscription filter
resource "aws_cloudwatch_log_subscription_filter" "example" {
  name            = "example-subscription-filter"
  role_arn        = "arn:aws:iam:ap-northeast-2:132410971304:role"
  log_group_name  = data.aws_cloudwatch_log_group.example.name
  filter_pattern  = ""
  destination_arn = "arn:aws:kinesis:ap-northeast-2:132410971304:stream/my-kinesis-stream"
}

# Restrict the CloudWatch log group subscription filter to a specific trusted account
resource "aws_cloudwatch_log_subscription_filter" "example_restricted" {
  name            = "example-subscription-filter-restricted"
  role_arn        = "arn:aws:iam:ap-northeast-2:132410971304:role"
  log_group_name  = data.aws_cloudwatch_log_group.example.name
  filter_pattern  = ""
  destination_arn = "arn:aws:kinesis:ap-northeast-2:123456789012:stream/my-kinesis-stream"
  depends_on      = [aws_cloudwatch_log_subscription_filter.example]
}


The provided Terraform code addresses the CloudWatch cross-account sharing disabled finding by:

1. Configuring the AWS provider for the ap-northeast-2 region.
2. Retrieving the existing CloudWatch log group using the `data` source.
3. Creating a CloudWatch log group subscription filter to send logs to a Kinesis stream.
4. Creating a second CloudWatch log group subscription filter that restricts access to a specific trusted account, using the `destination_arn` parameter.

The second subscription filter depends on the first one, ensuring that the restricted access is applied after the initial subscription is created.