# Enable VPC flow logs for the specified VPC
resource "aws_flow_log" "remediation_vpc_flow_logs" {
  traffic_type    = "ALL"
  vpc_id          = "vpc-0565167ce4f7cc871"
  log_destination = data.aws_s3_bucket.remediation_flow_logs_bucket.arn
}

# Create an S3 bucket to store the VPC flow logs
data "aws_s3_bucket" "remediation_flow_logs_bucket" {
  bucket = "my-vpc-flow-logs-bucket"
}

# Apply a bucket policy to the flow logs bucket to allow the VPC flow logs service to write logs
resource "aws_s3_bucket_policy" "remediation_flow_logs_bucket_policy" {
  bucket = data.aws_s3_bucket.remediation_flow_logs_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        },
        Action = "s3:PutObject",
        Resource = "${data.aws_s3_bucket.remediation_flow_logs_bucket.arn}/*"
      },
      {
        Effect = "Allow",
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        },
        Action = "s3:GetBucketAcl",
        Resource = data.aws_s3_bucket.remediation_flow_logs_bucket.arn
      }
    ]
  })
}