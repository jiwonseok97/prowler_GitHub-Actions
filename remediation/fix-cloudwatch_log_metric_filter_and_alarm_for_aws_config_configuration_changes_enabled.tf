# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create a CloudWatch Logs metric filter for AWS Config configuration changes
resource "aws_cloudwatch_log_metric_filter" "config_changes" {
  name           = "config-changes"
  pattern        = <<PATTERN
{ ($.eventSource = config.amazonaws.com) && (($.eventName = StopConfigurationRecorder) || ($.eventName = DeleteDeliveryChannel) || ($.eventName = PutDeliveryChannel) || ($.eventName = PutConfigurationRecorder)) }
PATTERN
  log_group_name = "arn:aws:logs:ap-northeast-2:132410971304:log-group"

  metric_transformation {
    name      = "ConfigChanges"
    namespace = "MyApp/Audit"
    value     = "1"
  }
}

# Create a CloudWatch alarm for the metric filter
resource "aws_cloudwatch_metric_alarm" "config_changes_alarm" {
  alarm_name          = "config-changes-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "ConfigChanges"
  namespace           = "MyApp/Audit"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alarm when AWS Config configuration changes occur"
  alarm_actions       = ["arn:aws:sns:ap-northeast-2:132410971304:my-alarm-topic"]
}


This Terraform code creates a CloudWatch Logs metric filter and a CloudWatch alarm to detect and notify on AWS Config configuration changes. The metric filter looks for specific AWS Config events (`StopConfigurationRecorder`, `DeleteDeliveryChannel`, `PutDeliveryChannel`, `PutConfigurationRecorder`) in the CloudTrail logs. The alarm is triggered when the metric filter detects at least one event within a 60-second period, and it sends a notification to the specified SNS topic.