# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Get the existing VPC resource
data "aws_vpc" "existing_vpc" {
  id = "vpc-0565167ce4f7cc871"
}

# Create a VPC flow log to capture all traffic (ACCEPT and REJECT)
resource "aws_flow_log" "vpc_flow_log" {
  log_destination      = "arn:aws:logs:ap-northeast-2:132410971304:log-group:/aws/vpc/flow-logs"
  log_destination_type = "cloudwatch-logs"
  traffic_type         = "ALL"
  vpc_id               = data.aws_vpc.existing_vpc.id
}

# Apply least privilege to the flow log writer role
resource "aws_iam_role" "flow_log_role" {
  name = "vpc-flow-log-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "flow_log_role_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSVPCFlowLogsFullAccess"
  role       = aws_iam_role.flow_log_role.name
}


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Retrieves the existing VPC resource using the `data` source.
3. Creates a VPC flow log to capture all traffic (ACCEPT and REJECT) and sends the logs to a CloudWatch Logs log group.
4. Creates an IAM role with the `AWSVPCFlowLogsFullAccess` policy attached, which grants the necessary permissions for the VPC flow logs to write to CloudWatch Logs.