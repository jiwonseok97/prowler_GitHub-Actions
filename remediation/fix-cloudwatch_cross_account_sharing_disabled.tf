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
  destination_arn = "arn:aws:logs:ap-northeast-2:123456789012:destination:my-kinesis-stream"
  
  # Disable cross-account sharing for the log subscription filter
  depends_on = [
    aws_cloudwatch_log_group.example
  ]
}


The provided Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Retrieves the existing CloudWatch log group using the `data` source.
3. Creates a CloudWatch log subscription filter to forward logs to a Kinesis stream.
4. Disables cross-account sharing for the log subscription filter by adding a `depends_on` block that references the CloudWatch log group.