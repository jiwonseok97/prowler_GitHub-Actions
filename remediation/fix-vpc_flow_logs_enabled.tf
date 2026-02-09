# Enable VPC flow logs for the specified VPC
resource "aws_flow_log" "remediation_vpc_flow_logs" {
  vpc_id = "vpc-0565167ce4f7cc871"
  traffic_type = "ALL"
  log_format = "$${version} $${account-id} $${interface-id} $${srcaddr} $${dstaddr} $${srcport} $${dstport} $${protocol} $${packets} $${bytes} $${start-time} $${end-time} $${action} $${log-status}"
}

# Create an S3 bucket to store the VPC flow logs
resource "aws_s3_bucket" "remediation_flow_logs_bucket" {
  bucket = "my-vpc-flow-logs-bucket"
  acl    = "private"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    enabled = true

    transition {
      days          = 30
      storage_class = "GLACIER"
    }

    expiration {
      days = 90
    }
  }
}

# Grant the VPC flow logs service principal the required permissions to write logs to the S3 bucket
resource "aws_s3_bucket_policy" "remediation_flow_logs_bucket_policy" {
  bucket = aws_s3_bucket.remediation_flow_logs_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        },
        Action = "s3:PutObject",
        Resource = "${aws_s3_bucket.remediation_flow_logs_bucket.arn}/*"
      },
      {
        Effect = "Allow",
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        },
        Action = "s3:GetBucketAcl",
        Resource = aws_s3_bucket.remediation_flow_logs_bucket.arn
      }
    ]
  })
}

# Configure the provider for the ap-northeast-2 region