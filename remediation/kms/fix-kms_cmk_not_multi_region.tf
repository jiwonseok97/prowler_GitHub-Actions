# Create a new KMS key in the same Region as the existing key
resource "aws_kms_key" "remediation_kms_key" {
  description              = "Remediation KMS key"
  key_usage                = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  deletion_window_in_days  = 30
  enable_key_rotation      = true
  policy                   = data.aws_iam_policy_document.remediation_kms_key_policy.json
}

# Create a KMS key policy to allow necessary access
data "aws_iam_policy_document" "remediation_kms_key_policy" {
  statement {
    effect  = "Allow"
    actions = ["kms:*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}

# Rotate the existing single-Region KMS key to a multi-Region key
resource "aws_kms_replica_key" "remediation_kms_replica_key" {
  description     = "Remediation KMS replica key"
  primary_key_arn = "arn:aws:kms:ap-northeast-2:${data.aws_caller_identity.current.account_id}:key/257ddf3b-bb72-4f49-a185-6227d0d9b5d4"
  tags = {
    Environment = "Remediation"
  }
}
