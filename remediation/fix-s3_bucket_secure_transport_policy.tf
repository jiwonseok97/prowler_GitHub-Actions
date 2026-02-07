# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Get the existing S3 bucket resource
data "aws_s3_bucket" "aws_cloudtrail_logs" {
  bucket = "aws-cloudtrail-logs-132410971304-0971c04b"
}

# Create a new S3 bucket policy to enforce HTTPS-only access
resource "aws_s3_bucket_policy" "aws_cloudtrail_logs_policy" {
  bucket = data.aws_s3_bucket.aws_cloudtrail_logs.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "${data.aws_s3_bucket.aws_cloudtrail_logs.arn}",
        "${data.aws_s3_bucket.aws_cloudtrail_logs.arn}/*"
      ],
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY
}


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Retrieves the existing S3 bucket resource using the `data` source.
3. Creates a new S3 bucket policy resource to enforce HTTPS-only access to the S3 bucket.
   - The policy denies all actions (`s3:*`) on the bucket and its objects if the request is made over an insecure transport (`aws:SecureTransport=false`).