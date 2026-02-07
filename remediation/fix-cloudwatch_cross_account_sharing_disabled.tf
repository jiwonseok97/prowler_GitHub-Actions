# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Get the existing CloudWatch log group
data "aws_cloudwatch_log_group" "example" {
  name = "/aws/lambda/example-function"
}

# Create a CloudWatch log group subscription filter to restrict cross-account sharing
resource "aws_cloudwatch_log_subscription_filter" "example" {
  name            = "example-subscription-filter"
  role_arn        = "arn:aws:iam:ap-northeast-2:132410971304:role"
  log_group_name  = data.aws_cloudwatch_log_group.example.name
  filter_pattern  = ""
  destination_arn = "arn:aws:logs:ap-northeast-2:132410971304:destination:example-destination"
}


The provided Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Retrieves the existing CloudWatch log group using the `data` source.
3. Creates a CloudWatch log group subscription filter to restrict cross-account sharing. The `role_arn` parameter is set to the specified resource UID, and the `destination_arn` parameter is set to a specific log destination.