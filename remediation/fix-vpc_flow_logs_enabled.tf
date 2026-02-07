# Configure the AWS provider for the ap-northeast-2 region

# Get the existing VPC resource
data "aws_vpc" "existing_vpc" {
  id = "vpc-0565167ce4f7cc871"
}

# Create a new flow log for the existing VPC
resource "aws_flow_log" "vpc_flow_log" {
  iam_role_arn         = aws_iam_role.flow_log_role.arn
  log_destination      = aws_cloudwatch_log_group.flow_log_group.arn
  traffic_type         = "ALL"
  vpc_id               = data.aws_vpc.existing_vpc.id
  log_destination_type = "cloudwatch_logs"
}

# Create an IAM role for the flow log
resource "aws_iam_role" "flow_log_role" {
  name = "vpc-flow-log-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
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

# Attach the required policy to the IAM role
resource "aws_iam_role_policy_attachment" "flow_log_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSVPCFlowLogsRole"
  role       = aws_iam_role.flow_log_role.name
}

# Create a CloudWatch log group for the flow logs
resource "aws_cloudwatch_log_group" "flow_log_group" {
  name = "vpc-flow-logs"
}


# This Terraform code does the following:
# 
# 1. Configures the AWS provider for the `ap-northeast-2` region.
# 2. Retrieves the existing VPC resource using a data source.
# 3. Creates a new VPC flow log for the existing VPC, sending the logs to a CloudWatch log group.
# 4. Creates an IAM role with the necessary permissions for the VPC flow logs.
# 5. Attaches the required policy to the IAM role.
# 6. Creates a CloudWatch log group to store the VPC flow logs.