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

# Enforce least privilege by granting the CloudTrail service account the necessary permissions
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
      "Action": [
        "s3:GetBucketVersioning",
        "s3:PutBucketVersioning",
        "s3:GetBucketLocation",
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:PutObject",
        "s3:PutObjectAcl"
      ],
      "Resource": [
        "${data.aws_s3_bucket.cloudtrail_bucket.arn}",
        "${data.aws_s3_bucket.cloudtrail_bucket.arn}/*"
      ]
    }
  ]
}
POLICY
}


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Retrieves the existing CloudTrail trail using the `aws_cloudtrail_service_account` data source.
3. Retrieves the existing S3 bucket for the CloudTrail trail using the `aws_s3_bucket` data source.
4. Enables MFA delete on the CloudTrail log bucket using the `aws_s3_bucket_ownership_controls` and `aws_s3_bucket_versioning` resources.
5. Grants the CloudTrail service account the necessary permissions to the CloudTrail log bucket using the `aws_s3_bucket_policy` resource.