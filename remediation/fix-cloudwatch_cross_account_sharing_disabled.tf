# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Get the existing CloudWatch log group
data "aws_cloudwatch_log_group" "example" {
  name = "/aws/lambda/my-lambda-function"
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
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "${data.aws_cloudwatch_log_group.example.arn}",
      "Condition": {
        "StringNotEquals": {
          "aws:PrincipalAccount": "132410971304"
        }
      }
    }
  ]
}
POLICY
}


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Retrieves the existing CloudWatch log group using the `data.aws_cloudwatch_log_group` data source.
3. Creates a CloudWatch log group policy using `aws_cloudwatch_log_group_policy` resource.
4. The policy denies cross-account access to the CloudWatch log group, allowing only the specified AWS account (132410971304) to create log streams and put log events.