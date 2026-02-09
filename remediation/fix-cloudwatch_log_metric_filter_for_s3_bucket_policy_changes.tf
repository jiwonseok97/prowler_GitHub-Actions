# Retrieve the existing CloudWatch log group name using a data source
data "aws_cloudwatch_log_group" "existing_log_group" {
  name = "arn:aws:logs:ap-northeast-2:132410971304:log-group"
}

# Create a CloudWatch log metric filter for S3 bucket policy changes
resource "aws_cloudwatch_log_metric_filter" "remediation_s3_bucket_policy_changes" {
  name           = "remediation_s3_bucket_policy_changes"
  pattern        = jsonencode({
    eventSource = "s3.amazonaws.com"
    eventName   = ["PutBucketPolicy", "DeleteBucketPolicy"]
  })
  log_group_name = data.aws_cloudwatch_log_group.existing_log_group.name
  metric_transformation {
    name      = "S3BucketPolicyChanges"
    namespace = "MyApp/SecurityLogs"
    value     = "1"
  }
}

# Create a CloudWatch alarm for S3 bucket policy changes
resource "aws_cloudwatch_metric_alarm" "remediation_s3_bucket_policy_changes" {
  alarm_name          = "remediation_s3_bucket_policy_changes"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "S3BucketPolicyChanges"
  namespace           = "MyApp/SecurityLogs"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alarm when S3 bucket policy changes are detected"
  alarm_actions       = ["arn:aws:sns:ap-northeast-2:132410971304:my-security-topic"]
}