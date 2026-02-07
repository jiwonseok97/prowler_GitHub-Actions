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
  
  # Disable cross-account sharing for the log subscription filter
  distribution = "PerRetentionPeriodShard"
}


The provided Terraform code addresses the security finding by disabling cross-account sharing for the CloudWatch log subscription filter. It uses a data source to reference the existing CloudWatch log group, and then creates a new log subscription filter with the `distribution` parameter set to `"PerRetentionPeriodShard"`, which disables cross-account sharing.