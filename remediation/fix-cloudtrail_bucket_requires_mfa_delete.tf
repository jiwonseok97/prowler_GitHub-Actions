# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Get the existing CloudTrail trail resource
data "aws_cloudtrail" "security_cloudtrail" {
  name = "security-cloudtail"
}

# Enable MFA delete on the CloudTrail log bucket
resource "aws_s3_bucket_ownership_controls" "cloudtrail_bucket_ownership_controls" {
  bucket = data.aws_cloudtrail.security_cloudtrail.s3_bucket_name
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_versioning" "cloudtrail_bucket_versioning" {
  bucket = data.aws_cloudtrail.security_cloudtrail.s3_bucket_name
  versioning_configuration {
    status = "Enabled"
    mfa_delete = "Enabled"
  }
}


The provided Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Retrieves the existing CloudTrail trail resource using the `data` source.
3. Enables MFA delete on the CloudTrail log bucket by:
   - Setting the bucket ownership controls to `BucketOwnerPreferred`.
   - Enabling versioning and MFA delete on the bucket.

This ensures that the CloudTrail log bucket has MFA delete enabled, providing an additional layer of security for the log files.