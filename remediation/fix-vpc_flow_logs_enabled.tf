# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Get the existing VPC resource
data "aws_vpc" "existing_vpc" {
  id = "vpc-0565167ce4f7cc871"
}

# Create a new flow log for the existing VPC
resource "aws_flow_log" "vpc_flow_log" {
  name                = "vpc-flow-log"
  vpc_id             = data.aws_vpc.existing_vpc.id
  traffic_type        = "ALL"
  destination_type    = "s3"
  destination_arn     = aws_s3_bucket.flow_log_bucket.arn
  log_destination_type = "s3"
  log_group_name      = "/aws/vpc-flow-logs"
}

# Create an S3 bucket to store the VPC flow logs
resource "aws_s3_bucket" "flow_log_bucket" {
  bucket = "my-vpc-flow-log-bucket"
  acl    = "private"
}

# Apply least privilege access to the S3 bucket
resource "aws_s3_bucket_public_access_block" "flow_log_bucket_access" {
  bucket = aws_s3_bucket.flow_log_bucket.id
  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls  = true
  restrict_public_buckets = true
}


The provided Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Retrieves the existing VPC resource using the `data` source.
3. Creates a new VPC flow log resource to capture all traffic (`traffic_type = "ALL"`) and sends the logs to an S3 bucket.
4. Creates an S3 bucket to store the VPC flow logs.
5. Applies least privilege access to the S3 bucket by blocking public access.