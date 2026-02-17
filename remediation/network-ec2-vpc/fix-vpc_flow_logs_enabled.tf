#
# Enable VPC flow logs for the specified VPC
#
resource "aws_flow_log" "remediation_vpc_flow_logs" {
  vpc_id           = "vpc-0565167ce4f7cc871"
  traffic_type     = "ALL"
  log_format       = "$${version} $${account-id} $${interface-id} $${srcaddr} $${dstaddr} $${srcport} $${dstport} $${protocol} $${packets} $${bytes} $${start-time} $${end-time} $${action} $${log-status}"
}

resource "aws_s3_bucket" "remediation_vpc_flow_logs_bucket" {
  bucket = "remediation-vpc-flow-logs-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"

}

resource "aws_s3_bucket_public_access_block" "remediation_vpc_flow_logs_bucket_access" {
  bucket = aws_s3_bucket.remediation_vpc_flow_logs_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
