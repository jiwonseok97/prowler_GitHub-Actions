#
# Enable VPC Flow Logs for the specified VPC
#
resource "aws_flow_log" "remediation_vpc_flow_logs" {
  vpc_id          = "vpc-0565167ce4f7cc871"
  traffic_type    = "ALL"
  log_destination = aws_cloudwatch_log_group.remediation_vpc_flow_logs.arn
  log_format      = "$${version} $${account-id} $${interface-id} $${srcaddr} $${dstaddr} $${srcport} $${dstport} $${protocol} $${packets} $${bytes} $${start} $${end} $${action} $${log-status}"
}

resource "aws_cloudwatch_log_group" "remediation_vpc_flow_logs" {
  name              = "remediation-vpc-flow-logs"
  retention_in_days = 365
}
