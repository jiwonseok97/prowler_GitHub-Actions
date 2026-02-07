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
  destination_arn = "arn:aws:logs:ap-northeast-2:123456789012:destination:example-destination"
}

# Restrict the CloudWatch log group subscription filter to a specific trusted account
resource "aws_cloudwatch_log_subscription_filter" "example_restricted" {
  name            = "example-subscription-filter-restricted"
  role_arn        = "arn:aws:iam:ap-northeast-2:132410971304:role"
  log_group_name  = data.aws_cloudwatch_log_group.example.name
  filter_pattern  = ""
  destination_arn = "arn:aws:logs:ap-northeast-2:123456789012:destination:example-destination"
  depends_on      = [aws_cloudwatch_log_subscription_filter.example]

  destination_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam:ap-northeast-2:123456789012:root"
      },
      "Action": "logs:PutSubscriptionFilter",
      "Resource": "arn:aws:logs:ap-northeast-2:123456789012:destination:example-destination"
    }
  ]
}
POLICY
}


The provided Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Retrieves the existing CloudWatch log group using the `data` source.
3. Creates a CloudWatch log group subscription filter to send logs to a specific destination.
4. Creates a second CloudWatch log group subscription filter that restricts access to the destination to a specific trusted account, using the `destination_policy` argument.