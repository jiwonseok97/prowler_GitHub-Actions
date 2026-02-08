# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Reference the existing single-region KMS key via data source
data "aws_kms_key" "existing" {
  key_id = "acf8da0a-9167-44bc-9373-b769fda7443b"
}

# Create a new multi-region KMS customer managed key as replacement
resource "aws_kms_key" "multi_region_key" {
  description             = "Multi-Region KMS Customer Managed Key"
  key_usage               = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  multi_region            = true
  enable_key_rotation     = true
}

# Alias for the new multi-region key
resource "aws_kms_alias" "multi_region_alias" {
  name          = "alias/multi-region-cmk"
  target_key_id = aws_kms_key.multi_region_key.key_id
}
