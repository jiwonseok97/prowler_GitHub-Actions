provider "aws" {
  region = "ap-northeast-2"
}

# Create a new multi-region KMS key
resource "aws_kms_key" "multi_region_key" {
  description             = "Multi-Region KMS Key"
  key_usage               = "ENCRYPT_DECRYPT"
  is_enabled              = true
  enable_key_rotation     = true
  multi_region            = true
}

# Import the existing single-region KMS key
resource "aws_kms_key" "single_region_key" {
  provider = aws.ap-northeast-2
  key_id  = "acf8da0a-9167-44bc-9373-b769fda7443b"
}