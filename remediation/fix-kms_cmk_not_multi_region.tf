# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Data source to reference the existing KMS key
data "aws_kms_key" "existing_key" {
  key_id = "acf8da0a-9167-44bc-9373-b769fda7443b"
}

# Create a new multi-region KMS key
resource "aws_kms_key" "multi_region_key" {
  description             = "Multi-Region KMS Key"
  deletion_window_in_days = 30
  is_enabled              = true
  multi_region            = true
}

# Replicate the existing KMS key to the new multi-region key
resource "aws_kms_replica_key" "replica_key" {
  description             = "Replica of the existing KMS key"
  deletion_window_in_days = 30
  primary_key_arn         = data.aws_kms_key.existing_key.arn
}


The provided Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Uses a `data` source to reference the existing KMS key with the specified resource UID.
3. Creates a new multi-region KMS key with the `aws_kms_key` resource.
4. Replicates the existing KMS key to the new multi-region key using the `aws_kms_replica_key` resource.

This should address the security finding by creating a multi-region KMS key and replicating the existing single-region key to it.