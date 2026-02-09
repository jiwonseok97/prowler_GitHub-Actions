# Remediation: kms_cmk_not_multi_region
# Create a new multi-region KMS key
# (AWS does not allow converting existing single-region keys to multi-region)

provider "aws" {
  region = "ap-northeast-2"
}

resource "aws_kms_key" "multi_region_key" {
  description             = "Multi-Region KMS Key (remediation)"
  key_usage               = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  multi_region            = true
  enable_key_rotation     = true
}

resource "aws_kms_alias" "multi_region_key_alias" {
  name          = "alias/multi-region-remediated"
  target_key_id = aws_kms_key.multi_region_key.key_id
}
