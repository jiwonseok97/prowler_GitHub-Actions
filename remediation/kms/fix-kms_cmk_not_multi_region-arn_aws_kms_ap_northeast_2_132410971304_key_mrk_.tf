# Create a new multi-Region KMS key
resource "aws_kms_key" "remediation_multi_region_key" {
  description              = "Remediation multi-Region KMS key"
  key_usage                = "ENCRYPT_DECRYPT"
}

# Replicate the existing single-Region key to the new multi-Region key
resource "aws_kms_replica_key" "remediation_replica_key" {
  description              = "Remediation replica of single-Region KMS key"
  primary_key_arn          = "arn:aws:kms:ap-northeast-2:${data.aws_caller_identity.current.account_id}:key/mrk-f1521e58e8ad4ebe8b256ce42889c389"
}

# Update the existing single-Region key policy to allow cross-Region replication
data "aws_kms_key" "existing_single_region_key" {
  key_id = "mrk-f1521e58e8ad4ebe8b256ce42889c389"
}

resource "aws_kms_key_policy" "remediation_single_region_key_policy" {
  key_id = data.aws_kms_key.existing_single_region_key.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action = [
          "kms:*"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Principal = {
          Service = "kms.amazonaws.com"
        },
        Action = [
          "kms:CreateGrant",
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:GenerateDataKey*",
          "kms:ReplicateKey",
          "kms:RetireGrant",
          "kms:RevokeGrant"
        ],
        Resource = "*"
      }
    ]
  })
}
