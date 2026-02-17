#Enable VPC flow logs for the specified VPC
resource "aws_flow_log" "remediation_vpc_flow_logs" {
  vpc_id           = "vpc-0565167ce4f7cc871"
  traffic_type     = "ALL"
}

#Create an S3 bucket to store the VPC flow logs
resource "aws_s3_bucket" "remediation_vpc_flow_logs_bucket" {
  bucket = "remediation-vpc-flow-logs-bucket-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"

}

#Grant the VPC flow logs service principal the required permissions to write logs to the S3 bucket
resource "aws_s3_bucket_policy" "remediation_vpc_flow_logs_bucket_policy" {
  bucket = aws_s3_bucket.remediation_vpc_flow_logs_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        },
        Action   = "s3:PutObject",
        Resource = "${aws_s3_bucket.remediation_vpc_flow_logs_bucket.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
      },
      {
        Effect = "Allow",
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        },
        Action   = "s3:GetBucketAcl",
        Resource = aws_s3_bucket.remediation_vpc_flow_logs_bucket.arn
      }
    ]
  })
}
