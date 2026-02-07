# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Get the existing VPC resource
data "aws_vpc" "existing_vpc" {
  id = "vpc-0565167ce4f7cc871"
}

# Create a VPC flow log to capture all traffic (both accepted and rejected)
resource "aws_flow_log" "vpc_flow_log" {
  log_destination      = "arn:aws:logs:ap-northeast-2:132410971304:log-group:/aws/vpc/flow-logs"
  log_destination_type = "cloudwatch_logs"
  traffic_type         = "ALL"
  vpc_id               = data.aws_vpc.existing_vpc.id
}


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Retrieves the existing VPC resource using the `data` source.
3. Creates a VPC flow log resource to capture all traffic (both accepted and rejected) for the existing VPC. The logs are sent to a CloudWatch Logs group named `/aws/vpc/flow-logs`.