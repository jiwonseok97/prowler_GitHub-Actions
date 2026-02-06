# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Get the existing CloudTrail trail
data "aws_cloudtrail" "security_cloudtrail" {
  name = "security-cloudtail"
}

# Enable log file validation on the CloudTrail trail
resource "aws_cloudtrail" "security_cloudtrail" {
  name                          = data.aws_cloudtrail.security_cloudtrail.name
  s3_bucket_name                = data.aws_cloudtrail.security_cloudtrail.s3_bucket_name
  s3_key_prefix                 = data.aws_cloudtrail.security_cloudtrail.s3_key_prefix
  is_multi_region_trail         = data.aws_cloudtrail.security_cloudtrail.is_multi_region_trail
  include_global_service_events = data.aws_cloudtrail.security_cloudtrail.include_global_service_events
  is_organization_trail         = data.aws_cloudtrail.security_cloudtrail.is_organization_trail
  kms_key_id                    = data.aws_cloudtrail.security_cloudtrail.kms_key_id
  log_file_validation_enabled   = true # Enable log file validation
}


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Retrieves the existing CloudTrail trail named `security-cloudtail` using the `data` source.
3. Updates the CloudTrail trail resource to enable log file validation by setting the `log_file_validation_enabled` attribute to `true`.

The code uses the `data` source to reference the existing CloudTrail trail and its associated attributes, such as the S3 bucket name, key prefix, and other configuration settings. This ensures that the updated CloudTrail trail maintains the same configuration as the existing one, except for the log file validation setting.