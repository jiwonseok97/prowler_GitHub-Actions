variable "vpc_id" {
  type        = string
  description = "The ID of the VPC for which to enable VPC Flow Logs"
  default     = ""
}

variable "flow_logs_bucket_name" {
  type        = string
  description = "The name of the S3 bucket to store the VPC Flow Logs"
  default     = ""
}

resource "aws_flow_log" "remediation_vpc_flow_logs" {
  traffic_type    = "ALL"
  vpc_id          = var.vpc_id
  log_destination = aws_s3_bucket.remediation_vpc_flow_logs.arn
}

resource "aws_s3_bucket" "remediation_vpc_flow_logs" {
  bucket = var.flow_logs_bucket_name
}

resource "aws_s3_bucket_ownership_controls" "remediation_vpc_flow_logs" {
  bucket = aws_s3_bucket.remediation_vpc_flow_logs.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "remediation_vpc_flow_logs" {
  bucket = aws_s3_bucket.remediation_vpc_flow_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "remediation_vpc_flow_logs_policy" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]
    resources = [
      "arn:aws:logs:*:*:log-group:/aws/flow-logs/*",
    ]
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
  }
}

resource "aws_s3_bucket_policy" "remediation_vpc_flow_logs" {
  bucket = aws_s3_bucket.remediation_vpc_flow_logs.id
  policy = data.aws_iam_policy_document.remediation_vpc_flow_logs_policy.json
}
