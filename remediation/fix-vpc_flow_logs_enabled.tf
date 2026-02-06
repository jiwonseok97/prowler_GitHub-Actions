# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Get the existing VPC resource
data "aws_vpc" "existing_vpc" {
  id = "vpc-0565167ce4f7cc871"
}

# Create a CloudWatch log group to store the VPC flow logs
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name = "vpc-flow-logs"
  retention_in_days = 90
}

# Create the VPC flow log to capture all traffic (ACCEPT and REJECT)
resource "aws_flow_log" "vpc_flow_log" {
  log_destination      = aws_cloudwatch_log_group.vpc_flow_logs.arn
  log_destination_type = "cloudwatch-logs"
  traffic_type         = "ALL"
  vpc_id               = data.aws_vpc.existing_vpc.id
}


The provided Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Retrieves the existing VPC resource using the `data` source.
3. Creates a CloudWatch log group named `vpc-flow-logs` with a retention period of 90 days.
4. Creates a VPC flow log to capture all traffic (both `ACCEPT` and `REJECT`) and sends the logs to the CloudWatch log group.