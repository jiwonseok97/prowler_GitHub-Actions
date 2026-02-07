# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Get the existing CloudTrail trail
data "aws_cloudtrail_service_account" "current" {}

data "aws_cloudtrail" "security_cloudtrail" {
  name = "security-cloudtail"
}

# Enable log file validation on the existing CloudTrail trail
resource "aws_cloudtrail" "security_cloudtrail" {
  name                          = data.aws_cloudtrail.security_cloudtrail.name
  s3_bucket_name                = data.aws_cloudtrail.security_cloudtrail.s3_bucket_name
  s3_key_prefix                 = data.aws_cloudtrail.security_cloudtrail.s3_key_prefix
  is_multi_region_trail         = data.aws_cloudtrail.security_cloudtrail.is_multi_region_trail
  include_global_service_events = data.aws_cloudtrail.security_cloudtrail.include_global_service_events
  is_organization_trail         = data.aws_cloudtrail.security_cloudtrail.is_organization_trail
  kms_key_id                    = data.aws_cloudtrail.security_cloudtrail.kms_key_id
  cloud_watch_logs_group_arn    = data.aws_cloudtrail.security_cloudtrail.cloud_watch_logs_group_arn
  cloud_watch_logs_role_arn      = data.aws_cloudtrail.security_cloudtrail.cloud_watch_logs_role_arn
  log_file_validation_enabled   = true # Enable log file validation
}


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Retrieves the existing CloudTrail trail named `security-cloudtail` using the `data.aws_cloudtrail` data source.
3. Updates the existing CloudTrail trail by setting `log_file_validation_enabled` to `true`, which enables log file integrity validation.
4. The rest of the CloudTrail trail configuration is preserved from the existing trail.