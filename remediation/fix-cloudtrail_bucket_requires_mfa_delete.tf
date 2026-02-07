# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Get the existing CloudTrail trail S3 bucket
data "aws_s3_bucket" "cloudtrail_bucket" {
  bucket = "security-cloudtail"
}

# Enable MFA delete on the CloudTrail log bucket
resource "aws_s3_bucket_ownership_controls" "cloudtrail_bucket_ownership_controls" {
  bucket = data.aws_s3_bucket.cloudtrail_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_versioning" "cloudtrail_bucket_versioning" {
  bucket = data.aws_s3_bucket.cloudtrail_bucket.id
  versioning_configuration {
    status = "Enabled"
    mfa_delete = "Enabled"
  }
}


The provided Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Retrieves the existing CloudTrail trail S3 bucket using the `aws_s3_bucket` data source.
3. Enables MFA delete on the CloudTrail log bucket by:
   - Setting the object ownership to "BucketOwnerPreferred" using the `aws_s3_bucket_ownership_controls` resource.
   - Enabling versioning and MFA delete on the bucket using the `aws_s3_bucket_versioning` resource.

This ensures that the CloudTrail log bucket has MFA delete enabled, which addresses the security finding.