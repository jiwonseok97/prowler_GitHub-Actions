# Create a CloudWatch Logs metric filter and alarm to monitor VPC route table changes
resource "aws_cloudwatch_log_metric_filter" "remediation_route_table_changes_filter" {
  name = "remediation-route-table-changes-filter"
  pattern        = "{$.eventName = CreateRoute} || {$.eventName = CreateRouteTable} || {$.eventName = ReplaceRoute} || {$.eventName = ReplaceRouteTableAssociation} || {$.eventName = DeleteRouteTable} || {$.eventName = DeleteRoute} || {$.eventName = DisassociateRouteTable}"
  log_group_name = var.cloudtrail_log_group_name

  metric_transformation {
    name = "RouteTableChanges"
    namespace = "MyApp/SecurityMetrics"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "remediation_route_table_changes_alarm" {
  alarm_name          = "remediation-route-table-changes-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = aws_cloudwatch_log_metric_filter.remediation_route_table_changes_filter.name
  namespace           = "MyApp/SecurityMetrics"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alarm when a VPC route table is created, modified, or deleted"
  alarm_actions       = ["arn:aws:sns:ap-northeast-2:${data.aws_caller_identity.current.account_id}:my-security-notifications"]
}

# Use data sources to reference existing IAM resources
data "aws_iam_role" "existing_security_role" {
  name = "my-security-role"
}

data "aws_iam_policy_document" "remediation_route_table_changes_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "cloudwatch:PutMetricData"
    ]
    resources = [
      "arn:aws:logs:ap-northeast-2:${data.aws_caller_identity.current.account_id}:log-group:YOUR_CLOUDTRAIL_LOG_GROUP_NAME",
      "arn:aws:cloudwatch:ap-northeast-2:${data.aws_caller_identity.current.account_id}:namespace/MyApp/SecurityMetrics"
    ]
  }
}

data "aws_iam_policy" "remediation_route_table_changes_policy" {
  arn = var.iam_policy_arn
  name = "remediation-route-table-changes-policy"
}


# Create an SNS topic to receive notifications
resource "aws_sns_topic" "remediation_security_notifications" {
  name = "remediation-security-notifications"
}

# Attach a policy to the SNS topic to allow CloudWatch Alarms to publish to it
data "aws_iam_policy_document" "remediation_sns_topic_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "SNS:Publish"
    ]
    principals {
      type        = "Service"
      identifiers = ["cloudwatch.amazonaws.com"]
    }
    resources = [
      aws_sns_topic.remediation_security_notifications.arn
    ]
  }
}

resource "aws_sns_topic_policy" "remediation_sns_topic_policy" {
  policy = jsonencode(data.aws_iam_policy_document.remediation_sns_topic_policy_document.json)
  arn = aws_sns_topic.remediation_security_notifications.arn
}

variable "cloudtrail_log_group_name" {
  description = "CloudTrail CloudWatch log group name"
  type        = string
}


variable "iam_policy_arn" {
  description = "Existing IAM policy ARN"
  type        = string
}