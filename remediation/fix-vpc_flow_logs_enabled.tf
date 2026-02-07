# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Get the existing VPC resource
data "aws_vpc" "existing_vpc" {
  id = "vpc-0565167ce4f7cc871"
}

# Create a new flow log for the existing VPC
resource "aws_flow_log" "vpc_flow_log" {
  log_destination      = "arn:aws:logs:ap-northeast-2:132410971304:log-group:/aws/vpc/flow-logs"
  log_destination_type = "cloudwatch_logs"
  traffic_type         = "ALL"
  vpc_id               = data.aws_vpc.existing_vpc.id
}


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Retrieves the existing VPC resource using the `data` source.
3. Creates a new VPC flow log resource for the existing VPC, with the following configurations:
   - The log destination is set to a CloudWatch Logs log group with the ARN `arn:aws:logs:ap-northeast-2:132410971304:log-group:/aws/vpc/flow-logs`.
   - The log destination type is set to `cloudwatch_logs`.
   - The traffic type is set to `ALL`, which captures all traffic (both accepted and rejected).
   - The VPC ID is set to the ID of the existing VPC.