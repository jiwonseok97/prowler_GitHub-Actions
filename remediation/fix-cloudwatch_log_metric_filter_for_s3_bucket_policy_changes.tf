# Create a CloudWatch log group to capture S3 bucket policy changes
resource "aws_cloudwatch_log_group" "remediation_s3_bucket_policy_changes_log_group" {
  name = "remediation-s3-bucket-policy-changes-log-group"
}

# Create a CloudWatch log metric filter to capture S3 bucket policy changes
resource "aws_cloudwatch_log_metric_filter" "remediation_s3_bucket_policy_changes_metric_filter" {
  name           = "remediation-s3-bucket-policy-changes-metric-filter"
  pattern        = "{$.eventSource = s3.amazonaws.com && $.eventName = PutBucketPolicy}"
  log_group_name = aws_cloudwatch_log_group.remediation_s3_bucket_policy_changes_log_group.name

  metric_transformation {
    name      = "S3BucketPolicyChanges"
    namespace = "MyApplication"
    value     = "1"
  }
}

# Create a CloudWatch alarm to trigger on S3 bucket policy changes
resource "aws_cloudwatch_metric_alarm" "remediation_s3_bucket_policy_changes_alarm" {
  alarm_name          = "remediation-s3-bucket-policy-changes-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = aws_cloudwatch_log_metric_filter.remediation_s3_bucket_policy_changes_metric_filter.metric_transformation[0].name
  namespace           = aws_cloudwatch_log_metric_filter.remediation_s3_bucket_policy_changes_metric_filter.metric_transformation[0].namespace
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alarm when S3 bucket policy changes are detected"
  alarm_actions       = ["arn:aws:sns:ap-northeast-2:132410971304:my-security-notifications"]
}