# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Reference the existing KMS key
data "aws_kms_key" "existing_key" {
  key_id = "acf8da0a-9167-44bc-9373-b769fda7443b"
}

# Create a new multi-region KMS key
resource "aws_kms_key" "multi_region_key" {
  description             = "Multi-Region KMS Key"
  deletion_window_in_days = 30
  multi_region            = true
}

# Create an alias for the new multi-region KMS key
resource "aws_kms_alias" "multi_region_key_alias" {
  name          = "alias/multi-region-key"
  target_key_id = aws_kms_key.multi_region_key.key_id
}

# Migrate existing resources to use the new multi-region KMS key
# Replace the existing key with the new multi-region key