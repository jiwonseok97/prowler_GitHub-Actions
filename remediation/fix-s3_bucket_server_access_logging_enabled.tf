# TODO: Manual remediation required for s3_bucket_server_access_logging_enabled
# Title: S3 bucket has server access logging enabled
# Last validation error: ::error::Terraform exited with code 1.   Error: Reference to undeclared resource    on candidate.tf line 33, in resource "aws_cloudtrail" "remediation_aws_cloudtrail":   33:     aws_s3_bucket_acl.reme
resource "null_resource" "remediation_s3_bucket_server_access_logging_enabled" {
  triggers = {
    check_id     = "s3_bucket_server_access_logging_enabled"
    resource_uid = "arn:aws:s3:::aws-cloudtrail-logs-132410971304-0971c04b"
  }
}
