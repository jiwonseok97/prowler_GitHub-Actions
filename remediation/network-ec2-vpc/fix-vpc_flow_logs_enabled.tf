#
# Enable VPC Flow Logs for the specified VPC
#
resource "aws_flow_log" "remediation_vpc_flow_logs" {
  traffic_type    = "ALL"
  vpc_id          = "vpc-0565167ce4f7cc871"
  log_destination = "arn:aws:logs:ap-northeast-2:${data.aws_caller_identity.current.account_id}:log-group:/aws/flowlogs/vpc-0565167ce4f7cc871"
  log_format      = "$${version} $${account-id} $${interface-id} $${srcaddr} $${dstaddr} $${srcport} $${dstport} $${protocol} $${packets} $${bytes} $${start} $${end} $${action} $${log-status}"
}
