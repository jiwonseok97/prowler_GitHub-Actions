#
# Enable VPC flow logs for the specified VPC
#
resource "aws_flow_log" "remediation_vpc_flow_logs" {
  vpc_id           = "vpc-0565167ce4f7cc871"
  traffic_type     = "ALL"
  log_destination  = data.aws_s3_bucket.remediation_vpc_flow_logs_bucket.arn
}

#
# Create an S3 bucket to store the VPC flow logs
#
data "aws_s3_bucket" "remediation_vpc_flow_logs_bucket" {
  bucket = "remediation-vpc-flow-logs-bucket"
}

#
# Create an IAM role and policy to allow the VPC flow logs to be written to the S3 bucket
#
data "aws_iam_policy_document" "remediation_vpc_flow_logs_bucket_policy" {
  statement {
    actions = [
      "s3:PutObject",
    ]
    resources = [
      "${data.aws_s3_bucket.remediation_vpc_flow_logs_bucket.arn}/*",
    ]
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
  }
}

resource "aws_s3_bucket_policy" "remediation_vpc_flow_logs_bucket_policy" {
  bucket = data.aws_s3_bucket.remediation_vpc_flow_logs_bucket.id
  policy = data.aws_iam_policy_document.remediation_vpc_flow_logs_bucket_policy.json
}
