# Configure the AWS provider for the ap-northeast-2 region

# Get the existing S3 bucket resource
data "aws_s3_bucket" "aws_cloudtrail_logs" {
  bucket = "aws-cloudtrail-logs-132410971304-0971c04b"
}

# Update the S3 bucket to disable ACLs and enforce bucket owner access
resource "aws_s3_bucket_ownership_controls" "aws_cloudtrail_logs" {
  bucket = data.aws_s3_bucket.aws_cloudtrail_logs.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Apply the bucket owner full control ACL to the S3 bucket
resource "aws_s3_bucket_acl" "aws_cloudtrail_logs" {
  depends_on = [aws_s3_bucket_ownership_controls.aws_cloudtrail_logs]
  bucket = data.aws_s3_bucket.aws_cloudtrail_logs.id
  acl    = "bucket-owner-full-control"
}


The provided Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Retrieves the existing S3 bucket resource using the `data` source.
3. Updates the S3 bucket to disable ACLs and enforce bucket owner access using the `aws_s3_bucket_ownership_controls` resource.
4. Applies the `bucket-owner-full-control` ACL to the S3 bucket using the `aws_s3_bucket_acl` resource, which depends on the previous step to ensure the bucket owner access is enforced.