# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Get the existing VPC resource
data "aws_vpc" "example_vpc" {
  id = "vpc-0565167ce4f7cc871"
}

# Create a VPC flow log to capture all traffic (ACCEPT and REJECT)
resource "aws_flow_log" "example_vpc_flow_log" {
  log_destination      = "arn:aws:logs:ap-northeast-2:132410971304:log-group:/aws/vpc/flow-logs"
  log_destination_type = "cloudwatch-logs"
  traffic_type         = "ALL"
  vpc_id               = data.aws_vpc.example_vpc.id
}

# Grant the necessary permissions for the VPC flow log to write to CloudWatch Logs
resource "aws_iam_role" "example_vpc_flow_log_role" {
  name = "example-vpc-flow-log-role"

  assume_role_policy = <<-EOF
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

resource "aws_iam_role_policy_attachment" "example_vpc_flow_log_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSVPCFlowLogsFullAccess"
  role       = aws_iam_role.example_vpc_flow_log_role.name
}


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Retrieves the existing VPC resource using the `data` source.
3. Creates a VPC flow log to capture all traffic (both `ACCEPT` and `REJECT`) for the specified VPC.
4. Configures an IAM role and attaches the `AWSVPCFlowLogsFullAccess` policy to grant the necessary permissions for the VPC flow log to write to CloudWatch Logs.