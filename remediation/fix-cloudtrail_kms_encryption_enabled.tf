# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Get the existing CloudTrail trail
data "aws_cloudtrail_service_account" "current" {}

data "aws_cloudtrail_trail" "security_cloudtrail" {
  name = "security-cloudtail"
}

# Create a new KMS key for encrypting the CloudTrail logs
resource "aws_kms_key" "cloudtrail_kms_key" {
  description             = "KMS key for encrypting CloudTrail logs"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

# Create an alias for the KMS key
resource "aws_kms_alias" "cloudtrail_kms_key_alias" {
  name          = "alias/cloudtrail-kms-key"
  target_key_id = aws_kms_key.cloudtrail_kms_key.key_id
}

# Update the existing CloudTrail trail to use the new KMS key for encryption
resource "aws_cloudtrail_service_account" "current" {
  provider = aws.current
}

resource "aws_cloudtrail" "security_cloudtrail" {
  name                          = "security-cloudtail"
  s3_bucket_name                = data.aws_cloudtrail_trail.security_cloudtrail.s3_bucket_name
  s3_key_prefix                 = data.aws_cloudtrail_trail.security_cloudtrail.s3_key_prefix
  is_multi_region_trail         = data.aws_cloudtrail_trail.security_cloudtrail.is_multi_region_trail
  include_global_service_events = data.aws_cloudtrail_trail.security_cloudtrail.include_global_service_events
  kms_key_id                    = aws_kms_key.cloudtrail_kms_key.arn
}


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Retrieves the existing CloudTrail trail named `security-cloudtail` using the `aws_cloudtrail_trail` data source.
3. Creates a new KMS key for encrypting the CloudTrail logs, with key rotation enabled.
4. Creates an alias for the KMS key.
5. Updates the existing CloudTrail trail to use the new KMS key for encryption.