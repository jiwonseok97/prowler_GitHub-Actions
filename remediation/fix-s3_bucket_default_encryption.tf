# Enable default server-side encryption (SSE) on the existing S3 bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "remediation_s3_bucket_encryption" {
  bucket = "aws-cloudtrail-logs-132410971304-0971c04b"

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Optionally, you can also enable KMS-based encryption for better key control and auditing
# resource "aws_kms_key" "remediation_s3_bucket_kms_key" {
#   description             = "KMS key for S3 bucket encryption"
#   deletion_window_in_days = 10
# }
# 
# resource "aws_s3_bucket_server_side_encryption_configuration" "remediation_s3_bucket_encryption" {
#   bucket = "aws-cloudtrail-logs-132410971304-0971c04b"
# 
#   rule {
#     apply_server_side_encryption_by_default {
#       kms_master_key_id = aws_kms_key.remediation_s3_bucket_kms_key.id
#       sse_algorithm     = "aws:kms"
#     }
#   }
# }