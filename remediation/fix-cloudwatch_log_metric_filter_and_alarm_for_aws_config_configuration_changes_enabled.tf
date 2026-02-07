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

# Create a CloudWatch alarm to notify on AWS Config configuration changes
resource "aws_cloudwatch_metric_alarm" "config_changes_alarm" {
  alarm_name          = "config-changes-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = aws_cloudwatch_log_metric_filter.config_changes.metric_transformation[0].name
  namespace           = aws_cloudwatch_log_metric_filter.config_changes.metric_transformation[0].namespace
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alarm when AWS Config configuration changes occur"
  alarm_actions       = ["arn:aws:sns:ap-northeast-2:132410971304:my-alarm-topic"]
}


The Terraform code above does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Creates a CloudWatch Logs metric filter to capture AWS Config configuration changes, including `StopConfigurationRecorder`, `DeleteDeliveryChannel`, `PutDeliveryChannel`, and `PutConfigurationRecorder` events.
3. Creates a CloudWatch alarm that triggers when the `ConfigChanges` metric, defined in the metric filter, is greater than or equal to 1. This alarm will notify the `my-alarm-topic` SNS topic.