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
  distribution    = "Random"
}


The provided Terraform code addresses the CloudWatch cross-account sharing disabled finding by creating a CloudWatch log group subscription filter. This filter allows you to forward log events from the specified log group to a destination, which can be another AWS service or an external service.

The key points of the code are:

1. The `provider` block configures the AWS provider for the `ap-northeast-2` region.
2. The `data` block retrieves the existing CloudWatch log group named `/aws/lambda/my-lambda-function`.
3. The `resource` block creates a CloudWatch log subscription filter that forwards log events from the specified log group to the destination with the ARN `arn:aws:logs:ap-northeast-2:123456789012:destination:example-destination`.
4. The `role_arn` parameter is set to the existing IAM role with the ARN `arn:aws:iam:ap-northeast-2:132410971304:role`, which is the resource identified in the security finding.

By applying this Terraform code, you can enable cross-account sharing for the specified CloudWatch log group, addressing the security finding.