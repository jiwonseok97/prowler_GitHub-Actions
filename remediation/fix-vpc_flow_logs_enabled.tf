# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Get the existing VPC resource
data "aws_vpc" "existing_vpc" {
  id = "vpc-0565167ce4f7cc871"
}

# Create a VPC flow log to capture all traffic (including REJECT)
resource "aws_flow_log" "vpc_flow_log" {
  name           = "vpc-flow-log"
  traffic_type   = "ALL"
  vpc_id         = data.aws_vpc.existing_vpc.id
  log_destination = "arn:aws:logs:ap-northeast-2:132410971304:log-group:/aws/vpc/flow-logs"
  log_destination_type = "cloudwatch-logs"
  tags = {
    Name = "VPC Flow Log"
  }
}


The provided Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Retrieves the existing VPC resource using the `data` source.
3. Creates a VPC flow log resource to capture all traffic (including `REJECT`) for the existing VPC.
4. Specifies the log destination as a CloudWatch Logs log group with the ARN `arn:aws:logs:ap-northeast-2:132410971304:log-group:/aws/vpc/flow-logs`.
5. Adds a tag to the VPC flow log resource for identification.