# Create a CloudWatch Logs log group to receive CloudTrail logs
resource "aws_cloudwatch_log_group" "remediation_cloudtrail_logs" {
  name = "remediation-cloudtrail-logs"
}

# Create a CloudWatch Logs metric filter to detect AWS Organizations changes
resource "aws_cloudwatch_log_metric_filter" "remediation_organizations_changes" {
  name           = "remediation-organizations-changes"
  pattern        = "{$.eventSource = organizations.amazonaws.com}"
  log_group_name = aws_cloudwatch_log_group.remediation_cloudtrail_logs.name

  metric_transformation {
    name      = "OrganizationsChanges"
    namespace = "MyApp/SecurityMetrics"
    value     = "1"
  }
}

# Create a CloudWatch alarm to notify on AWS Organizations changes
resource "aws_cloudwatch_metric_alarm" "remediation_organizations_changes_alarm" {
  alarm_name          = "remediation-organizations-changes-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = aws_cloudwatch_log_metric_filter.remediation_organizations_changes.metric_transformation[0].name
  namespace           = aws_cloudwatch_log_metric_filter.remediation_organizations_changes.metric_transformation[0].namespace
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alarm when changes are made to AWS Organizations"
  alarm_actions       = ["arn:aws:sns:ap-northeast-2:${data.aws_caller_identity.current.account_id}:my-security-notifications"]
}


# Attach a policy to the CloudTrail role to allow writing logs to CloudWatch
data "aws_iam_policy_document" "remediation_cloudtrail_logs_policy" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [
      aws_cloudwatch_log_group.remediation_cloudtrail_logs.arn,
    ]
  }
}

resource "aws_iam_role_policy" "remediation_cloudtrail_logs_policy" {
  name   = "remediation-cloudtrail-logs-policy"
  role   = "CloudTrailRole"
  policy = data.aws_iam_policy_document.remediation_cloudtrail_logs_policy.json
}