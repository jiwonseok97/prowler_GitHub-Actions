#
# Remediate the "kms_cmk_not_multi_region" finding by converting the single-Region KMS key to a multi-Region key
#

resource "aws_kms_key" "remediation_multi_region_key" {
  description              = "Remediation multi-Region KMS key"
  key_usage                = "ENCRYPT_DECRYPT"
  deletion_window_in_days  = 30
  multi_region             = true
}

#
# Replicate the existing single-Region KMS key to the new multi-Region key
#

resource "aws_kms_replica_key" "remediation_replica_key" {
  description              = "Replica of the existing single-Region KMS key"
  deletion_window_in_days  = 30
  primary_key_arn          = "arn:aws:kms:ap-northeast-2:${data.aws_caller_identity.current.account_id}:key/257ddf3b-bb72-4f49-a185-6227d0d9b5d4"
  depends_on               = [aws_kms_key.remediation_multi_region_key]
}
