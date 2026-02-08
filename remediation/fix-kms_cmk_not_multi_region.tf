provider "aws" {
  region = "ap-northeast-2"
}

# Create a new KMS key in the ap-northeast-2 region
resource "aws_kms_key" "multi_region_key" {
  description             = "Multi-Region KMS Key"
  key_usage               = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  multi_region            = true
}

# Import the existing single-Region KMS key
resource "aws_kms_key" "existing_key" {
  key_id = "acf8da0a-9167-44bc-9373-b769fda7443b"
}

# Migrate data encrypted with the existing single-Region key to the new multi-Region key
data "aws_kms_ciphertext" "encrypted_data" {
  key_id    = aws_kms_key.existing_key.key_id
  plaintext = "your_plaintext_data"
}

resource "aws_kms_ciphertext" "encrypted_with_multi_region_key" {
  key_id    = aws_kms_key.multi_region_key.key_id
  plaintext = data.aws_kms_ciphertext.encrypted_data.ciphertext_blob
}