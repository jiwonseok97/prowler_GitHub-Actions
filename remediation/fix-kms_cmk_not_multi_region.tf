provider "aws" {
  region = "ap-northeast-2"
}

# Create a new KMS key in the ap-northeast-2 region
resource "aws_kms_key" "multi_region_key" {
  description             = "Multi-Region KMS key"
  key_usage               = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  multi_region            = true
}

# Import the existing single-Region KMS key
resource "aws_kms_key" "single_region_key" {
  provider = aws
  key_id  = "acf8da0a-9167-44bc-9373-b769fda7443b"
}