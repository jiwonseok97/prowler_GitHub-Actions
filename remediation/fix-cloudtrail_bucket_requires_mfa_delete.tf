# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Get the existing CloudTrail trail
data "aws_cloudtrail_service_account" "current" {}

# Get the existing S3 bucket for the CloudTrail trail
data "aws_s3_bucket" "cloudtrail_bucket" {
  bucket = "security-cloudtail"
}

# Enable MFA delete on the CloudTrail log bucket
resource "aws_s3_bucket_ownership_controls" "cloudtrail_bucket" {
  bucket = data.aws_s3_bucket.cloudtrail_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_versioning" "cloudtrail_bucket" {
  bucket = data.aws_s3_bucket.cloudtrail_bucket.id
  versioning_configuration {
    status = "Enabled"
    mfa_delete = "Enabled"
  }
}

# Grant the CloudTrail service account the necessary permissions to write logs to the S3 bucket
resource "aws_s3_bucket_policy" "cloudtrail_bucket_policy" {
  bucket = data.aws_s3_bucket.cloudtrail_bucket.id
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "${data.aws_cloudtrail_service_account.current.arn}"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "${data.aws_s3_bucket.cloudtrail_bucket.arn}"
        },
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "${data.aws_cloudtrail_service_account.current.arn}"
            },
            "Action": "s3:PutObject",
            "Resource": "${data.aws_s3_bucket.cloudtrail_bucket.arn}/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        }
    ]
}
POLICY
}


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Retrieves the existing CloudTrail trail using the `aws_cloudtrail_service_account` data source.
3. Retrieves the existing S3 bucket for the CloudTrail trail using the `aws_s3_bucket` data source.
4. Enables MFA delete on the CloudTrail log bucket by creating an `aws_s3_bucket_ownership_controls` resource and an `aws_s3_bucket_versioning` resource.
5. Grants the CloudTrail service account the necessary permissions to write logs to the S3 bucket by creating an `aws_s3_bucket_policy` resource.