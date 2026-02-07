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

# Update the existing single-region KMS customer managed key to be multi-region
resource "aws_kms_key" "existing_key" {
  arn                     = "arn:aws:kms:ap-northeast-2:132410971304:key/acf8da0a-9167-44bc-9373-b769fda7443b"
  description             = "Multi-Region KMS Customer Managed Key"
  key_usage               = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  multi_region            = true
}


The provided Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Creates a new multi-region KMS customer managed key with the specified description, key usage, and customer master key spec.
3. Updates the existing single-region KMS customer managed key to be a multi-region key by setting the `multi_region` attribute to `true`.