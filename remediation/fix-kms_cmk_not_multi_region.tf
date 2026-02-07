# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create a new multi-region KMS customer managed key
resource "aws_kms_key" "multi_region_key" {
  description             = "Multi-Region KMS Customer Managed Key"
  key_usage               = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  is_enabled              = true
  enable_key_rotation     = true
  multi_region            = true
}

# Alias for the new multi-region KMS key
resource "aws_kms_alias" "multi_region_key_alias" {
  name          = "alias/multi-region-key"
  target_key_id = aws_kms_key.multi_region_key.key_id
}


The provided Terraform code creates a new multi-region KMS customer managed key and an alias for it. This addresses the security finding by creating a multi-region key, which is the recommended approach as per the provided recommendation.