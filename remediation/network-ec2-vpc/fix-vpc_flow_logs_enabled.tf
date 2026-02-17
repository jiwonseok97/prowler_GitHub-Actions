#Enable VPC flow logs for the specified VPC
resource "aws_flow_log" "remediation_vpc_flow_logs" {
  traffic_type    = "ALL"
  vpc_id          = "vpc-0565167ce4f7cc871"
  log_destination = aws_cloudwatch_log_group.remediation_vpc_flow_logs.arn
}

#Create a CloudWatch log group to store the VPC flow logs
resource "aws_cloudwatch_log_group" "remediation_vpc_flow_logs" {
  name = "remediation-vpc-flow-logs"
}

#Set the appropriate permissions for the CloudWatch log group
resource "aws_cloudwatch_log_resource_policy" "remediation_vpc_flow_logs_policy" {
  policy_name = "remediation-vpc-flow-logs-policy"
  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        },
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = aws_cloudwatch_log_group.remediation_vpc_flow_logs.arn
      }
    ]
  })
}
