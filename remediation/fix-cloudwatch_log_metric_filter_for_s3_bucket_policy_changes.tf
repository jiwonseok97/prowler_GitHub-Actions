# Create a CloudWatch log group to capture S3 bucket policy changes
resource "aws_cloudwatch_log_group" "remediation_s3_bucket_policy_changes" {
  name = "s3-bucket-policy-changes"
}

# Create a CloudWatch log metric filter to track S3 bucket policy changes
resource "aws_cloudwatch_log_metric_filter" "remediation_s3_bucket_policy_changes" {
  name           = "s3-bucket-policy-changes"
  pattern        = "{$.eventSource = s3.amazonaws.com && $.eventName = PutBucketPolicy}"
  log_group_name = aws_cloudwatch_log_group.remediation_s3_bucket_policy_changes.name

  metric_transformation {
    name      = "S3BucketPolicyChanges"
    namespace = "MyApp/SecurityMetrics"
    value     = "1"
  }
}

# Create a CloudWatch alarm to trigger on S3 bucket policy changes
resource "aws_cloudwatch_metric_alarm" "remediation_s3_bucket_policy_changes" {
  alarm_name          = "s3-bucket-policy-changes"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = aws_cloudwatch_log_metric_filter.remediation_s3_bucket_policy_changes.name
  namespace           = "MyApp/SecurityMetrics"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alarm when an S3 bucket policy is changed"
  alarm_actions       = ["arn:aws:sns:ap-northeast-2:${data.aws_caller_identity.current.account_id}:my-security-topic"]
}