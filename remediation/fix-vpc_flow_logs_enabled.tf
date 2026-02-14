# Enable VPC flow logs for the existing VPC
resource "aws_flow_log" "remediation_vpc_flow_logs" {
  traffic_type    = "ALL"
  vpc_id          = "vpc-0565167ce4f7cc871"
  log_destination = aws_cloudwatch_log_group.remediation_vpc_flow_logs.arn
}

# Create a CloudWatch log group to store the VPC flow logs
resource "aws_cloudwatch_log_group" "remediation_vpc_flow_logs" {
  name = "remediation-vpc-flow-logs"
}