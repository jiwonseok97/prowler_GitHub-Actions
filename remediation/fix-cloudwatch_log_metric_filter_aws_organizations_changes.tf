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
2. Creates a CloudWatch Logs metric filter for AWS Organizations changes, using the log group with the provided resource UID.
3. Creates a CloudWatch alarm for the Organizations changes metric, which will trigger an alarm when there is at least one change event. The alarm action is set to an SNS topic, which can be used to notify responders.