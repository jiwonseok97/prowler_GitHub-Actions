# Create a CloudWatch log metric filter to detect S3 bucket policy changes
resource "aws_cloudwatch_log_metric_filter" "remediation_s3_bucket_policy_changes" {
  name = "s3-bucket-policy-changes"
  pattern        = "{$.eventSource = s3.amazonaws.com && $.eventName = PutBucketPolicy}"
  log_group_name = "132410971304"

  metric_transformation {
    name = "S3BucketPolicyChanges"
    namespace = "SecurityMetrics"
    value     = "1"
  }
}

# Create a CloudWatch alarm to trigger on S3 bucket policy changes
resource "aws_cloudwatch_metric_alarm" "remediation_s3_bucket_policy_changes_alarm" {
  alarm_name          = "s3-bucket-policy-changes-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = aws_cloudwatch_log_metric_filter.remediation_s3_bucket_policy_changes.name
  namespace           = "SecurityMetrics"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alarm when S3 bucket policy changes are detected"
  alarm_actions       = [data.aws_sns_topic.security_alerts.arn]
}

# Use a data source to reference an existing SNS topic for security alerts
data "aws_sns_topic" "security_alerts" {
  name = "security-alerts"
}