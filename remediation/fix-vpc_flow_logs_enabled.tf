# Create an S3 bucket to store VPC flow logs
resource "aws_s3_bucket" "remediation_vpc_flow_logs_bucket" {
  bucket = "remediation-vpc-flow-logs-bucket-${data.aws_caller_identity.current.account_id}"
}

# Create an IAM role for the VPC flow logs
resource "aws_iam_role" "remediation_vpc_flow_logs_role" {
  name = "remediation-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })
}

# Attach the required IAM policy to the VPC flow logs role
resource "aws_iam_role_policy_attachment" "remediation_vpc_flow_logs_role_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSVPCFlowLogsRole"
  role       = aws_iam_role.remediation_vpc_flow_logs_role.name
}

# Enable VPC flow logs for the existing VPC
resource "aws_flow_log" "remediation_vpc_flow_logs" {
  vpc_id         = "vpc-0565167ce4f7cc871"
  traffic_type   = "ALL"
  log_destination_type = "s3"
  log_destination = aws_s3_bucket.remediation_vpc_flow_logs_bucket.arn
  iam_role_arn    = aws_iam_role.remediation_vpc_flow_logs_role.arn
}