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
    sid    = "Enable IAM User Permissions"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }
}

# Rotate the existing single-Region KMS key to a multi-Region key
resource "aws_kms_replica_key" "remediation_kms_replica_key" {
  description     = "Remediation KMS replica key"
  primary_key_arn = "arn:aws:kms:ap-northeast-2:${data.aws_caller_identity.current.account_id}:key/f17d8c4a-29b6-46a2-9ddf-47028e2506ac"
  tags = {
    Environment = "Remediation"
  }
}
