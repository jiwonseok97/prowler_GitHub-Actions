# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create a new multi-region KMS customer managed key
resource "aws_kms_key" "multi_region_key" {
  description             = "Multi-Region KMS Customer Managed Key"
  key_usage               = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  multi_region            = true
}

# Rotate the existing single-region KMS customer managed key
resource "aws_kms_key" "single_region_key" {
  arn                     = "arn:aws:kms:ap-northeast-2:132410971304:key/acf8da0a-9167-44bc-9373-b769fda7443b"
  enable_key_rotation     = true
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
}


The provided Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Creates a new multi-region KMS customer managed key with the following properties:
   - Description: "Multi-Region KMS Customer Managed Key"
   - Key usage: "ENCRYPT_DECRYPT"
   - Customer master key spec: "SYMMETRIC_DEFAULT"
   - Multi-region: `true`
3. Rotates the existing single-region KMS customer managed key with the following properties:
   - ARN: "arn:aws:kms:ap-northeast-2:132410971304:key/acf8da0a-9167-44bc-9373-b769fda7443b"
   - Enable key rotation: `true`
   - Customer master key spec: "SYMMETRIC_DEFAULT"