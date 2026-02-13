# Create a CloudWatch log metric filter to detect S3 bucket policy changes
resource "aws_cloudwatch_log_metric_filter" "remediation_s3_bucket_policy_changes" {
  name = "s3-bucket-policy-changes"
  pattern        = "{$.eventSource = s3.amazonaws.com && $.eventName = PutBucketPolicy}"
  log_group_name = "132410971304"

  metric_transformation {
    name = "S3BucketPolicyChanges"
    namespace = "MyApp/SecurityLogs"
    value     = "1"
  }
}

# Create a CloudWatch alarm to trigger on S3 bucket policy changes
resource "aws_cloudwatch_metric_alarm" "remediation_s3_bucket_policy_changes_alarm" {
  alarm_name          = "s3-bucket-policy-changes-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = aws_cloudwatch_log_metric_filter.remediation_s3_bucket_policy_changes.metric_transformation[0].name
  namespace           = aws_cloudwatch_log_metric_filter.remediation_s3_bucket_policy_changes.metric_transformation[0].namespace
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alarm when S3 bucket policy changes are detected"
  alarm_actions       = [aws_sns_topic.remediation_security_alerts.arn]
}

# Create an SNS topic to receive security alerts
resource "aws_sns_topic" "remediation_security_alerts" {
  name = "security-alerts"
}

# Attach a policy to the SNS topic to allow CloudWatch alarms to publish to it
resource "aws_sns_topic_policy" "remediation_security_alerts_policy" {

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        },
        Action = "sns:Publish",
        Resource = aws_sns_topic.remediation_security_alerts.arn
      }
    ]
  })
  arn = aws_sns_topic.remediation_security_alerts.arn
}