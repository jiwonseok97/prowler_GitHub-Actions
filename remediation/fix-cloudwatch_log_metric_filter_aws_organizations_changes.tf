# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create a CloudWatch Logs metric filter for AWS Organizations changes
resource "aws_cloudwatch_log_metric_filter" "organizations_changes" {
  name           = "organizations-changes"
  pattern        = "{$.eventSource = organizations.amazonaws.com}"
  log_group_name = "arn:aws:logs:ap-northeast-2:132410971304:log-group"

  metric_transformation {
    name      = "OrganizationsChanges"
    namespace = "MyApp/Metrics"
    value     = "1"
  }
}

# Create a CloudWatch alarm for the Organizations changes metric
resource "aws_cloudwatch_metric_alarm" "organizations_changes_alarm" {
  alarm_name          = "organizations-changes-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "OrganizationsChanges"
  namespace           = "MyApp/Metrics"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alarm when there are changes to AWS Organizations"
  alarm_actions       = ["arn:aws:sns:ap-northeast-2:132410971304:my-alert-topic"]
}


The provided Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Creates a CloudWatch Logs metric filter for AWS Organizations changes. The filter looks for events where the `eventSource` is `organizations.amazonaws.com`.
3. Creates a CloudWatch alarm that triggers when the "OrganizationsChanges" metric is greater than or equal to 1. This alarm will send notifications to the specified SNS topic.