provider "aws" {
  region = "ap-northeast-2"
}

# Create a CloudWatch log group for S3 bucket policy changes
resource "aws_cloudwatch_log_group" "s3_bucket_policy_changes" {
  name = "s3-bucket-policy-changes"
}

# Create a CloudWatch log metric filter for S3 bucket policy changes
resource "aws_cloudwatch_log_metric_filter" "s3_bucket_policy_changes" {
  name           = "s3-bucket-policy-changes"
  pattern        = "{$.eventSource = s3.amazonaws.com && $.eventName = PutBucketPolicy}"
  log_group_name = aws_cloudwatch_log_group.s3_bucket_policy_changes.name

  metric_transformation {
    name      = "S3BucketPolicyChanges"
    namespace = "MyApp/SecurityLogs"
    value     = "1"