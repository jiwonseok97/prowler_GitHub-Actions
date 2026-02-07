# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Get the existing CloudWatch log group
data "aws_cloudwatch_log_group" "example" {
  name = "/aws/lambda/example-function"
}

# Create a CloudWatch log group policy to restrict cross-account sharing
resource "aws_cloudwatch_log_group_policy" "example" {
  log_group_name = data.aws_cloudwatch_log_group.example.name

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Principal": {
        "AWS": "*"
      },
      "Action": [
        "logs:PutSubscriptionFilter",
        "logs:PutResourcePolicy"
      ],
      "Resource": "${data.aws_cloudwatch_log_group.example.arn}"
    }
  ]
}
POLICY
}


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Retrieves the existing CloudWatch log group using the `data` source.
3. Creates a CloudWatch log group policy that denies the `PutSubscriptionFilter` and `PutResourcePolicy` actions for all principals, effectively disabling cross-account sharing for the specified log group.